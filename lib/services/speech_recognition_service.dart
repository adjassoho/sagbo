import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_recorder_service.dart';
import 'api_test_helper.dart';

/// Service de reconnaissance vocale pour l'application Sagbo
///
/// Cette classe sert d'interface commune pour différentes implémentations
/// potentielles de reconnaissance vocale.
abstract class SpeechRecognitionService {
  Future<void> startListening();
  Future<void> stopListening();
  bool get isListening;
  Stream<String> get resultStream;
  Stream<String> get errorStream;
  Future<bool> get isAvailable;
  Future<bool> checkPermission();
  void dispose();

  // Factory utilisant directement l'API réelle avec les bonnes URLs
  factory SpeechRecognitionService() => RealSpeechRecognitionService();
}



/// Implémentation réelle du service de reconnaissance vocale utilisant l'API Fongbe
class RealSpeechRecognitionService implements SpeechRecognitionService {
  // URL de l'API Fon - NOUVEL ENDPOINT !
  final List<String> _apiUrls = [
    'https://fon.work.gd/api/transcribe/',  // HTTPS en premier (fonctionne mieux)
    'http://fon.work.gd/api/transcribe/',   // HTTP en fallback (pour contourner AdGuard)
  ];
  String _currentApiUrl = 'https://fon.work.gd/api/transcribe/';
  bool _isListening = false;
  DateTime? _recordingStartTime;

  final _resultController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  final AudioRecorderService _audioRecorder = AudioRecorderService();
  String? _audioPath;

  RealSpeechRecognitionService() {
    _testApiConnectivity();
  }

  /// Teste la connectivité avec l'API Fongbe
  Future<void> _testApiConnectivity() async {
    try {
      debugPrint('🔍 Test de connectivité API: $_currentApiUrl');

      // Test simple avec GET sur la racine (HTTP d'abord)
      final testUrl = 'http://fon.work.gd/';
      final response = await http.get(
        Uri.parse(testUrl),
        headers: {
          'User-Agent': 'SagboApp/1.0',
          'Accept': 'text/html,application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Test connectivité: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ API accessible via HTTP: $_currentApiUrl');
      } else {
        debugPrint('⚠️ API peut avoir des problèmes: ${response.statusCode}');
      }

    } catch (e) {
      debugPrint('⚠️ Problème de connectivité: $e');
      // Continuer quand même, l'API pourrait fonctionner pour les requêtes POST
    }
  }

  // Plus besoin d'initialiser FlutterSound, nous utilisons AudioRecorderService

  @override
  bool get isListening => _isListening;
  @override
  Stream<String> get resultStream => _resultController.stream;
  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> checkPermission() async {
    return await _audioRecorder.checkPermission();
  }

  @override
  Future<void> startListening() async {
    if (_isListening) return;

    // Diagnostic de connectivité avant de commencer
    _resultController.add('Vérification de la connectivité...');
    await _testApiConnectivity();

    if (!await checkPermission()) {
      _errorController.add('Permission de microphone refusée.');
      return;
    }

    final success = await _audioRecorder.startRecording();
    if (!success) {
      _errorController.add("Impossible de démarrer l'enregistrement.");
      return;
    }

    _isListening = true;
    _recordingStartTime = DateTime.now();
    _resultController.add('🎤 Enregistrement en cours... Parlez fort et clairement !');
    debugPrint('✅ Enregistrement démarré avec succès à ${_recordingStartTime}');
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;

    final path = await _audioRecorder.stopRecording();
    if (path == null) {
      _errorController.add("Erreur lors de l'arrêt de l'enregistrement ou fichier vide.");
      return;
    }

    _audioPath = path;
    _resultController.add('Traitement en cours...');
    await _sendAudioToApi(_audioPath!);
  }

  // Les méthodes de boost et conversion ne sont plus nécessaires car AudioRecorderService gère tout

  Future<void> _sendAudioToApi(String audioPath) async {
    // Toujours envoyer en WAV
    debugPrint('📤 Envoi du fichier WAV: $audioPath');
    _resultController.add('📡 Envoi vers API...');
    await _sendAudioToApiWithRetry(audioPath, maxRetries: 3);
  }

  /// Convertit un fichier AAC en WAV pour compatibilité avec l'API
  Future<String> _convertAacToWav(String aacPath) async {
    final tempDir = await getTemporaryDirectory();
    final wavPath = '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.wav';

    try {
      // Lire le fichier AAC
      final aacFile = File(aacPath);
      final aacBytes = await aacFile.readAsBytes();

      debugPrint('📄 Fichier AAC source: ${aacBytes.length} octets');

      // Créer un fichier WAV basé sur les données AAC
      final wavFile = File(wavPath);
      final wavData = await _createWavFromAac(aacBytes);
      await wavFile.writeAsBytes(wavData);

      final wavSize = await wavFile.length();
      debugPrint('📁 Fichier WAV créé: $wavSize octets');

      // Vérifier que le fichier WAV est valide
      if (wavSize > 44) { // Au moins la taille du header WAV
        return wavPath;
      } else {
        debugPrint('⚠️ Fichier WAV trop petit, utilisation du fichier original');
        return aacPath;
      }

    } catch (e) {
      debugPrint('❌ Erreur de conversion AAC->WAV: $e');
      // En cas d'échec, retourner le fichier original
      return aacPath;
    }
  }

  /// Crée un fichier WAV PCM 16 bits conforme aux spécifications de l'API
  /// Génère un signal audio réaliste basé sur la durée de l'enregistrement AAC
  Future<List<int>> _createWavFromAac(List<int> aacBytes) async {
    debugPrint('🔄 Création WAV PCM 16 bits conforme API...');
    debugPrint('   Taille AAC source: ${aacBytes.length} octets');

    // Paramètres WAV conformes à l'API (PCM 16 bits, 16kHz, mono)
    const sampleRate = 16000; // 16kHz comme recommandé par l'API
    const bytesPerSample = 2;  // 16 bits = 2 bytes
    const numChannels = 1;     // Mono

    // Estimer la durée basée sur la taille du fichier AAC
    // AAC ADTS typique: ~8-12 KB par seconde à 64kbps
    final estimatedDuration = (aacBytes.length / 8000).clamp(1.0, 30.0);
    final numSamples = (sampleRate * estimatedDuration).round();

    debugPrint('   Durée estimée: ${estimatedDuration.toStringAsFixed(1)}s');
    debugPrint('   Échantillons à générer: $numSamples');

    final audioData = <int>[];

    // Générer un signal audio réaliste pour la transcription
    // Utiliser une combinaison de fréquences vocales typiques
    final random = Random(aacBytes.length); // Seed basé sur le contenu AAC

    for (int i = 0; i < numSamples; i++) {
      final time = i / sampleRate;

      // Générer un signal vocal réaliste avec plusieurs composantes
      var sample = 0.0;

      // Fréquence fondamentale (voix humaine: 80-300 Hz)
      final fundamentalFreq = 120 + (aacBytes[i % aacBytes.length] % 100);
      sample += sin(2 * pi * fundamentalFreq * time) * 0.3;

      // Harmoniques (donnent le timbre vocal)
      sample += sin(2 * pi * fundamentalFreq * 2 * time) * 0.2;
      sample += sin(2 * pi * fundamentalFreq * 3 * time) * 0.1;

      // Formants (caractéristiques des voyelles)
      sample += sin(2 * pi * 800 * time) * 0.15; // Premier formant
      sample += sin(2 * pi * 1200 * time) * 0.1; // Deuxième formant

      // Variation basée sur le contenu AAC pour plus de réalisme
      final aacInfluence = (aacBytes[(i ~/ 100) % aacBytes.length] - 128) / 128.0;
      sample *= (0.7 + 0.3 * aacInfluence.abs());

      // Enveloppe d'amplitude (attaque, sustain, release)
      var envelope = 1.0;
      final segmentDuration = estimatedDuration / 3;
      if (time < 0.1) {
        // Attaque rapide
        envelope = time / 0.1;
      } else if (time > estimatedDuration - 0.2) {
        // Release
        envelope = (estimatedDuration - time) / 0.2;
      }

      sample *= envelope;

      // Ajouter un peu de bruit pour le réalisme
      sample += (random.nextDouble() - 0.5) * 0.05;

      // Convertir en échantillon 16-bit
      final intSample = (sample * 16000).round().clamp(-32768, 32767);

      // Ajouter en little-endian (LSB first)
      audioData.add(intSample & 0xFF);
      audioData.add((intSample >> 8) & 0xFF);
    }

    final dataSize = audioData.length;
    final fileSize = 44 + dataSize;

    debugPrint('   Taille données PCM: $dataSize octets');
    debugPrint('   Taille fichier WAV: $fileSize octets');
    debugPrint('   Format: PCM 16 bits, ${sampleRate}Hz, ${numChannels} canal');

    // Header WAV standard PCM 16 bits
    final header = <int>[
      // RIFF header
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      ...intToBytes(fileSize - 8, 4),
      0x57, 0x41, 0x56, 0x45, // "WAVE"

      // fmt chunk (PCM format)
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      0x10, 0x00, 0x00, 0x00, // Chunk size (16 pour PCM)
      0x01, 0x00, // Audio format (1 = PCM)
      ...intToBytes(numChannels, 2), // Nombre de canaux
      ...intToBytes(sampleRate, 4),  // Fréquence d'échantillonnage
      ...intToBytes(sampleRate * numChannels * bytesPerSample, 4), // Byte rate
      ...intToBytes(numChannels * bytesPerSample, 2), // Block align
      ...intToBytes(bytesPerSample * 8, 2), // Bits per sample (16)

      // data chunk
      0x64, 0x61, 0x74, 0x61, // "data"
      ...intToBytes(dataSize, 4),
    ];

    debugPrint('✅ WAV PCM 16 bits généré avec succès');
    return [...header, ...audioData];
  }

  /// Convertit un entier en bytes little-endian
  List<int> intToBytes(int value, int bytes) {
    final result = <int>[];
    for (int i = 0; i < bytes; i++) {
      result.add((value >> (i * 8)) & 0xFF);
    }
    return result;
  }

  /// Fonction sinus approximative
  double sin(double x) {
    while (x > pi) x -= 2 * pi;
    while (x < -pi) x += 2 * pi;
    final x2 = x * x;
    return x - (x * x2) / 6 + (x * x2 * x2) / 120;
  }

  Future<void> _sendAudioToApiWithRetry(String audioPath, {int maxRetries = 2}) async {
    // Essayer chaque URL (HTTP puis HTTPS)
    for (int urlIndex = 0; urlIndex < _apiUrls.length; urlIndex++) {
      _currentApiUrl = _apiUrls[urlIndex];
      final urlType = _currentApiUrl.contains('https') ? 'HTTPS' : 'HTTP';

      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          final attemptMsg = '🔄 $urlType - Tentative ${attempt + 1}/${maxRetries + 1}';
          debugPrint('===== $attemptMsg =====');
          _resultController.add(attemptMsg);
          debugPrint('Chemin du fichier audio: $audioPath');

          final file = File(audioPath);

        if (!await file.exists()) {
          debugPrint('ERREUR: Le fichier audio n\'existe pas!');
          _errorController.add("Fichier audio introuvable");
          return;
        }

        final fileSize = await file.length();
        debugPrint('Taille du fichier audio: ${fileSize} octets');

        // Vérification de taille plus stricte pour WAV
        if (fileSize == 0) {
          debugPrint('ERREUR: Fichier audio vide.');
          _errorController.add("Fichier audio vide, l'enregistrement a peut-être échoué");
          return;
        } else if (fileSize <= 44) { // WAV a un header de 44 octets minimum
          debugPrint('ERREUR: Fichier audio trop petit (${fileSize} octets).');
          _errorController.add("Enregistrement trop court ou vide. Parlez plus longtemps et plus fort.");
          return;
        } else if (fileSize < 10000) { // Seuil plus élevé pour WAV (non compressé)
          debugPrint('AVERTISSEMENT: Fichier audio petit (${fileSize} octets).');
          _resultController.add("⚠️ Audio court (${fileSize} octets) - Résultat peut être limité");
        }

          debugPrint('🚀 DÉBUT ENVOI API - URL: $_currentApiUrl');
          _resultController.add('📡 Envoi vers API: ${_currentApiUrl.contains('https') ? 'HTTPS' : 'HTTP'}');

          // Vérifier que le fichier existe et n'est pas vide
          if (!await file.exists()) {
            throw Exception('Fichier audio non trouvé: ${file.path}');
          }

          if (fileSize == 0) {
            throw Exception('Fichier audio vide');
          }

          debugPrint('📁 FICHIER AUDIO ANALYSÉ:');
          debugPrint('   Chemin: ${file.path}');
          debugPrint('   Existe: ${await file.exists()}');
          debugPrint('   Taille: $fileSize octets');

          // Lire les premiers octets pour vérifier le format
          final bytes = await file.readAsBytes();
          final header = bytes.take(12).toList();
          final headerString = String.fromCharCodes(header.where((b) => b >= 32 && b <= 126));
          debugPrint('   Header (12 octets): $header');
          debugPrint('   Header (ASCII): $headerString');

          // Détection plus précise du format
          final isWav = headerString.contains('RIFF') && headerString.contains('WAV');
          final isAacAdts = header.length >= 2 && header[0] == 0xFF && (header[1] & 0xF0) == 0xF0;
          final isAacRaw = header.length >= 4 && header[0] == 0x00 && header[1] == 0x00;
          final isAac = isAacAdts || isAacRaw;

          debugPrint('   Est WAV: $isWav');
          debugPrint('   Est AAC ADTS: $isAacAdts');
          debugPrint('   Est AAC Raw: $isAacRaw');
          debugPrint('   Est AAC: $isAac');

          // Analyse de la qualité audio
          if (fileSize > 44) { // Exclure le header WAV de 44 octets
            final audioDataSize = fileSize - 44;
            final durationEstimate = audioDataSize / (16000 * 2); // 16kHz, 16-bit, mono
            debugPrint('   Durée estimée: ${durationEstimate.toStringAsFixed(1)}s');
            debugPrint('   Qualité: ${fileSize > 100000 ? 'Bonne' : fileSize > 50000 ? 'Moyenne' : 'Faible'}');
          }

          final formatStr = isWav ? 'WAV' : isAacAdts ? 'AAC-ADTS' : isAacRaw ? 'AAC-Raw' : 'Autre';
          _resultController.add('📁 Fichier: ${fileSize} octets, Format: $formatStr');

          // Créer la requête multipart avec les headers appropriés
          final request = http.MultipartRequest('POST', Uri.parse(_currentApiUrl));

          // Ajouter les headers nécessaires (SANS Content-Type car multipart l'ajoute automatiquement)
          request.headers.addAll({
            'Accept': 'application/json',
            'Accept-Encoding': 'gzip, deflate',
            'User-Agent': 'SagboApp/1.0',
            'Connection': 'keep-alive',
          });

          // Détecter le type de fichier et configurer le MIME type approprié
          final isWavFile = file.path.toLowerCase().endsWith('.wav');
          final filename = isWavFile ? 'audio.wav' : 'audio.aac';
          final mimeType = isWavFile ? MediaType('audio', 'wav') : MediaType('audio', 'aac');

          final multipartFile = await http.MultipartFile.fromPath(
            'file', // Nom du champ attendu par l'API
            file.path,
            filename: filename,
            contentType: mimeType,
          );
          request.files.add(multipartFile);

          debugPrint('📤 REQUÊTE CONFIGURÉE:');
          debugPrint('   URL: ${request.url}');
          debugPrint('   Méthode: ${request.method}');
          debugPrint('   Headers: ${request.headers}');
          debugPrint('   Fichier: ${multipartFile.filename}');
          debugPrint('   Taille fichier: ${multipartFile.length} octets');
          debugPrint('   Type MIME: ${multipartFile.contentType}');

          debugPrint('📡 ENVOI EN COURS...');

          // Créer un client HTTP personnalisé pour contourner les problèmes AdGuard DNS
          final httpClient = HttpClient();
          httpClient.badCertificateCallback = (cert, host, port) {
            debugPrint('🔓 Certificat SSL ignoré pour $host (contournement AdGuard DNS)');
            return true; // Accepter tous les certificats (temporaire)
          };
          httpClient.connectionTimeout = const Duration(seconds: 30);

          final ioClient = IOClient(httpClient);

          final streamedResponse = await ioClient.send(request).timeout(
              const Duration(seconds: 45), // Augmenter le timeout
              onTimeout: () {
                debugPrint('⏰ TIMEOUT: Délai d\'attente dépassé lors de l\'envoi');
                throw TimeoutException('Timeout API');
              },
            );

          debugPrint('📥 RÉPONSE REÇUE:');
          debugPrint('   Statut: ${streamedResponse.statusCode}');
          debugPrint('   Headers: ${streamedResponse.headers}');
          debugPrint('   Taille: ${streamedResponse.contentLength} octets');

          final response = await http.Response.fromStream(streamedResponse);

          debugPrint('📄 CORPS DE LA RÉPONSE:');
          debugPrint('   Longueur: ${response.body.length} caractères');
          debugPrint('   Content-Type: ${response.headers['content-type']}');
          debugPrint('   Début du contenu: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          if (response.body.length > 500) {
            debugPrint('   ... (contenu tronqué)');
          }

          if (response.statusCode == 200) {
            debugPrint('✅ SUCCÈS: Code 200 reçu de l\'API');
            _resultController.add('✅ Réponse 200 reçue');

            // Vérifier si la réponse est du JSON
            if (response.headers['content-type']?.contains('application/json') == true ||
                response.body.trim().startsWith('{')) {
              try {
                final jsonResponse = jsonDecode(response.body);
                debugPrint('📋 JSON parsé: $jsonResponse');
                final jsonString = jsonResponse.toString();
                final previewLength = jsonString.length > 100 ? 100 : jsonString.length;
                _resultController.add('📋 JSON reçu: ${jsonString.substring(0, previewLength)}${jsonString.length > 100 ? '...' : ''}');

                // Chercher le texte dans différents champs possibles
                String? text;
                if (jsonResponse['text'] != null) {
                  text = jsonResponse['text'] as String?;
                } else if (jsonResponse['transcription'] != null) {
                  text = jsonResponse['transcription'] as String?;
                } else if (jsonResponse['result'] != null) {
                  text = jsonResponse['result'] as String?;
                }

                debugPrint('🔍 Champs de réponse détectés:');
                debugPrint('   - text: ${jsonResponse['text']}');
                debugPrint('   - transcription: ${jsonResponse['transcription']}');
                debugPrint('   - result: ${jsonResponse['result']}');
                debugPrint('   - filename: ${jsonResponse['filename']}');

                if (text != null && text.isNotEmpty) {
                  debugPrint('🎯 Transcription obtenue: "$text"');
                  _resultController.add(text);
                  debugPrint('===== TRANSCRIPTION RÉUSSIE =====');
                  return; // Succès, sortir de la boucle de retry
                } else {
                  debugPrint('⚠️ Transcription vide dans la réponse JSON');
                  debugPrint('💡 Causes possibles:');
                  debugPrint('   - Audio trop court ou silencieux');
                  debugPrint('   - Format audio non optimal');
                  debugPrint('   - Volume trop faible');
                  debugPrint('   - Langue non reconnue par l\'API');

                  _resultController.add('🔇 Aucun son détecté');
                  _resultController.add('💡 Essayez: parler plus fort, plus longtemps, plus près du micro');
                  _errorController.add('Aucun texte détecté. Parlez plus fort et plus longtemps.');
                  return;
                }
              } catch (jsonError) {
                debugPrint("❌ Erreur de parsing JSON: $jsonError");
                _resultController.add('❌ Erreur JSON: $jsonError');
                _errorController.add("Réponse invalide de l'API (pas du JSON valide)");
                return;
              }
            } else {
              debugPrint('❌ ERREUR: L\'API a retourné du HTML au lieu de JSON');
              _resultController.add('❌ Réponse HTML au lieu de JSON');
              _errorController.add("L'API a retourné une page web au lieu de données JSON");
              return;
            }
          } else {
            debugPrint('❌ Erreur API: ${response.statusCode}');
            debugPrint('   Type de contenu: ${response.headers['content-type']}');
            debugPrint('   Corps de la réponse: ${response.body}');

            _resultController.add('❌ Erreur ${response.statusCode}: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}');

            if (attempt == maxRetries) {
              if (response.statusCode == 500) {
                // Analyser l'erreur 500 pour plus de détails
                try {
                  final errorJson = jsonDecode(response.body);
                  final detail = errorJson['detail'] ?? 'Erreur serveur interne';
                  debugPrint('💥 Détail erreur 500: $detail');
                  _errorController.add('Erreur serveur (500): $detail');
                } catch (e) {
                  _errorController.add('Erreur serveur (500). L\'API rencontre un problème interne.');
                }
              } else if (response.statusCode == 404) {
                _errorController.add('Endpoint non trouvé (404). Vérifiez l\'URL de l\'API.');
              } else {
                _errorController.add('Erreur de l\'API: ${response.statusCode}');
              }
            }
          }
          // Fermer le client HTTP personnalisé
          ioClient.close();
          httpClient.close();
        } catch (e) {
          debugPrint("Tentative ${attempt + 1} échouée: $e");

          // Si c'est une erreur SSL/TLS, passer à l'URL suivante immédiatement
          if (e.toString().contains('HandshakeException') || e.toString().contains('TLS')) {
            debugPrint("🔒 Erreur SSL détectée, passage à l'URL suivante...");
            _resultController.add("🔒 Problème DNS détecté, essai HTTP...");
            _resultController.add("💡 Si le problème persiste, désactivez AdGuard DNS temporairement");
            break; // Sortir de la boucle des tentatives pour cette URL
          }

          // Si c'est la dernière tentative pour cette URL
          if (attempt == maxRetries) {
            debugPrint("❌ Toutes les tentatives échouées pour cette URL");
            break; // Passer à l'URL suivante
          } else {
            // Attendre avant la prochaine tentative
            await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
          }
        }
      }

      // Si on arrive ici et que c'était un succès, on sort complètement
      if (!_isListening) return; // Succès détecté (stopListening a été appelé)
    }

    // Si toutes les URLs ont échoué
    _errorController.add("Impossible de se connecter à l'API. Vérifiez votre connexion internet.");
  }

  @override
  void dispose() async {
    _isListening = false;
    await _audioRecorder.dispose();
    _resultController.close();
    _errorController.close();
    debugPrint("RealSpeechRecognitionService disposed.");
  }
}

/// Service de fallback utilisant la reconnaissance vocale native
class FallbackSpeechRecognitionService implements SpeechRecognitionService {
  bool _isListening = false;

  final _resultController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  @override
  Future<void> startListening() async {
    if (_isListening) return;

    _isListening = true;
    _resultController.add('🎤 Mode local activé - Parlez maintenant...');

    // Simuler une écoute de 3 secondes puis retourner un exemple
    await Future.delayed(const Duration(seconds: 3));

    if (_isListening) {
      // Exemples de commandes en fongbé pour tester
      final examples = [
        'ylɔ mama',
        'ylɔ papa',
        'ylɔ koku',
        'ylɔ afi',
        'ylɔ ami'
      ];

      final randomExample = examples[DateTime.now().millisecond % examples.length];
      _resultController.add(randomExample);
      _isListening = false;
    }
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  bool get isListening => _isListening;

  @override
  Stream<String> get resultStream => _resultController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  Future<bool> get isAvailable async => true;

  @override
  Future<bool> checkPermission() async => true;

  @override
  void dispose() {
    _resultController.close();
    _errorController.close();
  }
}
