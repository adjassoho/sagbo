import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'services/voice_command_processor.dart';
import 'services/contact_service.dart';
import 'services/certificate_helper.dart';
import 'config/custom_localizations_delegate.dart';
import 'config/language_manager.dart';
import 'config/app_localizations.dart';
import 'screens/permission_screen.dart';
import 'screens/test_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le helper de certificat pour ignorer les erreurs SSL
  HttpOverrides.global = SagboCertificateHelper();
  
  // Initialiser le gestionnaire de langue
  final languageManager = LanguageManager();
  await languageManager.initialize();
  
  runApp(MyApp(languageManager: languageManager));
}

class MyApp extends StatelessWidget {
  final LanguageManager languageManager;
  
  const MyApp({super.key, required this.languageManager});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: languageManager,
      child: Consumer<LanguageManager>(
        builder: (context, languageManager, _) {
          return MaterialApp(
            title: 'Sagbo',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            // Configuration des localisations
            locale: languageManager.currentLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              // Delegates personnalisés pour Fongbé
              FongbeMaterialLocalizations.delegate,
              FongbeCupertinoLocalizations.delegate,
            ],
            home: const PermissionWrapper(),
          );
        },
      ),
    );
  }
}

/// Wrapper qui gère l'affichage de l'écran de permissions ou de l'écran principal
class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  State<PermissionWrapper> createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  bool _permissionsGranted = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    try {
      // Vérifier si toutes les permissions requises sont accordées
      final permissions = [
        Permission.microphone,
        Permission.contacts,
        Permission.phone,
      ];

      bool allGranted = true;
      for (final permission in permissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          allGranted = false;
          break;
        }
      }

      setState(() {
        _permissionsGranted = allGranted;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      debugPrint('Erreur lors de la vérification initiale des permissions: $e');
      setState(() {
        _permissionsGranted = false;
        _isCheckingPermissions = false;
      });
    }
  }

  void _onPermissionsGranted() {
    setState(() {
      _permissionsGranted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      // Écran de chargement pendant la vérification
      final localizations = AppLocalizations.of(context);
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              Text(
                localizations?.translate('checking_permissions') ?? 'Vérification des permissions...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_permissionsGranted) {
      // Afficher l'écran de demande de permissions
      return PermissionScreen(
        onPermissionsGranted: _onPermissionsGranted,
      );
    }

    // Afficher l'écran principal
    return const HomeScreen();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _lastWords = '';
  String _lastResponse = '';
  String _apiStatus = 'Vérification...';
  bool _isApiOnline = true;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  // Services
  final VoiceCommandProcessor _voiceCommandProcessor = VoiceCommandProcessor();
  final ContactService _contactService = ContactService();
  
  // Gestion des abonnements aux streams
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    
    // Animation pour le logo
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
    
    // Initialiser les services
    _initializeServices();
    
    // S'abonner aux événements
    _subscribeToEvents();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Passer le contexte au processeur de commandes vocales pour les traductions
    _voiceCommandProcessor.setContext(context);
  }
  
  Future<void> _initializeServices() async {
    try {
      debugPrint('🚀 Initialisation des services...');

      // Précharger les contacts en arrière-plan
      _contactService.getContacts();

      // Initialiser le processeur de commandes vocales
      await _voiceCommandProcessor.initialize();

      debugPrint('✅ Services initialisés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation des services: $e');
    }
  }
  
  void _subscribeToEvents() {
    // État de l'écoute
    _subscriptions.add(
      _voiceCommandProcessor.listeningStateStream.listen((isListening) {
        setState(() {
          _isListening = isListening;
        });
      })
    );
    
    // Texte reconnu
    _subscriptions.add(
      _voiceCommandProcessor.recognizedTextStream.listen((text) {
        setState(() {
          _lastWords = text;
        });
      })
    );
    
    // Réponse aux commandes
    _subscriptions.add(
      _voiceCommandProcessor.commandResponseStream.listen((response) {
        setState(() {
          _lastResponse = response;
        });
      })
    );
    
    // Erreurs
    _subscriptions.add(
      _voiceCommandProcessor.errorStream.listen((error) {
        debugPrint('Erreur: $error');
        setState(() {
          final localizations = AppLocalizations.of(context);
          // Améliorer l'affichage des erreurs
          if (error.contains('API Fongbé indisponible')) {
            _lastResponse = localizations?.translate('api_unavailable') ?? 
                            '⚠️ Mode local activé\nL\'API est temporairement indisponible';
            _apiStatus = localizations?.translate('local_mode') ?? 'Mode local';
            _isApiOnline = false;
          } else if (error.contains('Erreur serveur (500)')) {
            _lastResponse = localizations?.translate('server_problem') ?? 
                            '🔧 Problème serveur\nEssayez à nouveau dans quelques instants';
            _apiStatus = localizations?.translate('server_error') ?? 'Erreur serveur';
            _isApiOnline = false;
          } else if (error.contains('Impossible de se connecter')) {
            _lastResponse = localizations?.translate('connection_problem') ?? 
                            '📡 Problème de connexion\nVérifiez votre internet';
            _apiStatus = localizations?.translate('offline') ?? 'Hors ligne';
            _isApiOnline = false;
          } else {
            _lastResponse = 'Erreur: $error';
            _apiStatus = localizations?.translate('error') ?? 'Erreur';
            _isApiOnline = false;
          }
        });
      })
    );
  }
  
  @override
  void dispose() {
    // Annuler tous les abonnements
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }

    // Annuler le timer
    _recordingTimer?.cancel();

    // Libérer les ressources
    _voiceCommandProcessor.dispose();
    _animationController.dispose();

    super.dispose();
  }

  void _toggleListening() {
    if (_isListening) {
      _recordingTimer?.cancel();
      _voiceCommandProcessor.stopListening();
    } else {
      setState(() {
        _lastResponse = '';
        _recordingSeconds = 0;
      });

      // Démarrer le timer d'enregistrement
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });

      _voiceCommandProcessor.startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            Text(
              AppLocalizations.of(context)?.translate('app_title') ?? 'Sagbo',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
            // Indicateur de statut API
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isApiOnline ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isApiOnline 
                    ? AppLocalizations.of(context)?.translate('online') ?? 'En ligne'
                    : _apiStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isApiOnline ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // Bouton de changement de langue
          Consumer<LanguageManager>(
            builder: (context, languageManager, _) {
              return IconButton(
                icon: Text(
                  languageManager.currentLanguageFlag,
                  style: const TextStyle(fontSize: 20),
                ),
                tooltip: languageManager.currentLanguageName,
                onPressed: () {
                  languageManager.toggleLanguage();
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Fond d'écran avec faible opacité
          Positioned.fill(
            child: Opacity(
              opacity: 0.08, // Opacité très faible pour que l'image soit à peine visible
              child: Image.asset(
                'assets/images/background.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Contenu principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Sagbo avec animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 180,
                        height: 180,
                        margin: const EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.deepPurple[900],
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        // Utiliser l'image du logo au lieu de la lettre S
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo_sagbo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                // État actuel
                Text(
                  _isListening
                    ? AppLocalizations.of(context)?.translate('listening_in_progress', [_recordingSeconds.toString()]) ?? 'Écoute en cours... (${_recordingSeconds}s)'
                    : AppLocalizations.of(context)?.translate('main_greeting') ?? 'ZIN BO ƉƆ XÓ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                // Indication de durée minimale
                if (_isListening && _recordingSeconds < 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      AppLocalizations.of(context)?.translate('speak_minimum') ?? 'Parlez au moins 2 secondes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[300],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Texte reconnu
                if (_lastWords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _lastWords,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Réponse de l'assistant
                if (_lastResponse.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _lastResponse,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 30),
                
                // Bouton d'activation
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? Colors.deepPurple
                          : Colors.black.withOpacity(0.6),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isListening
                              ? Colors.deepPurple.withOpacity(0.6)
                              : Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Bouton flottant pour les tests
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TestCallScreen()),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.phone_in_talk),
        tooltip: 'Test d\'appel',
      ),
    );
  }
}
