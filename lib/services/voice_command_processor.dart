import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import 'contact_service.dart';
import 'contact_backup_service.dart';
import 'fongbe_translation_service.dart';
import 'speech_recognition_service.dart';
import '../config/app_localizations.dart';

/// Service qui coordonne la reconnaissance vocale, la traduction,
/// et l'exécution des commandes vocales
class VoiceCommandProcessor {
  // Singleton pattern
  static final VoiceCommandProcessor _instance = VoiceCommandProcessor._internal();
  factory VoiceCommandProcessor() => _instance;
  VoiceCommandProcessor._internal();

  // Services utilisés
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final ContactService _contactService = ContactService();
  final ContactBackupService _backupService = ContactBackupService();
  final FongbeTranslationService _translationService = FongbeTranslationService();

  // Stream controllers
  final _listeningStateController = StreamController<bool>.broadcast();
  final _recognizedTextController = StreamController<String>.broadcast();
  final _commandResponseController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  // État
  bool _isInitialized = false;

  // Getters pour les streams
  Stream<bool> get listeningStateStream => _listeningStateController.stream;
  Stream<String> get recognizedTextStream => _recognizedTextController.stream;
  Stream<String> get commandResponseStream => _commandResponseController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // Contexte pour les traductions (optionnel)
  BuildContext? _context;
  
  /// Définit le contexte pour les traductions
  void setContext(BuildContext context) {
    _context = context;
  }
  
  /// Traduit une clé si le contexte est disponible
  String _t(String key, [List<String>? params]) {
    if (_context != null) {
      return AppLocalizations.of(_context!)?.translate(key, params) ?? key;
    }
    return key;
  }

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Vérifier la disponibilité de la reconnaissance vocale
    if (!await _speechService.isAvailable) {
      _errorController.add(_t('voice_not_available'));
      return;
    }

    // Vérifier les permissions
    if (!await _speechService.checkPermission()) {
      _errorController.add(_t('microphone_permission_denied'));
      return;
    }

    // Écouter les résultats de la reconnaissance vocale
    _speechService.resultStream.listen(_processRecognitionResult);
    _speechService.errorStream.listen(_errorController.add);
    
    // Synchroniser les contacts en arrière-plan
    _backupService.autoSync().then((_) {
      debugPrint(_t('contacts_synced_success'));
    }).catchError((error) {
      debugPrint(_t('contacts_sync_error', [error.toString()]));
    });

    _isInitialized = true;
  }

  /// Démarre l'écoute vocale
  Future<void> startListening() async {
    if (!_isInitialized) await initialize();

    try {
      await _speechService.startListening();
      _listeningStateController.add(true);
    } catch (e) {
      _errorController.add(_t('listening_start_error', [e.toString()]));
      _listeningStateController.add(false);
    }
  }

  /// Arrête l'écoute vocale
  Future<void> stopListening() async {
    if (!_isInitialized) return;

    try {
      await _speechService.stopListening();
      _listeningStateController.add(false);
    } catch (e) {
      _errorController.add(_t('listening_stop_error', [e.toString()]));
    }
  }

  /// Traite le résultat de la reconnaissance vocale
  Future<void> _processRecognitionResult(String recognizedText) async {
    _recognizedTextController.add(recognizedText);

    // Analyser la commande
    final parsedCommand = _translationService.parseVoiceCommand(recognizedText);
    final command = parsedCommand['command'];
    final parameter = parsedCommand['parameter'];

    if (command == null) {
      _commandResponseController.add(_t('command_not_recognized'));
      return;
    }

    // Traiter les différents types de commandes
    switch (command) {
      case 'call':
        await _processCallCommand(parameter);
        break;
      // Ajouter d'autres types de commandes ici
      default:
        _commandResponseController.add(_t('command_not_supported'));
    }
  }

  /// Traite une commande d'appel téléphonique
  Future<void> _processCallCommand(String? contactName) async {
    if (contactName == null || contactName.isEmpty) {
      _commandResponseController.add(_t('no_contact_specified'));
      return;
    }

    _commandResponseController.add(_t('searching_contact', [contactName]));

    try {
      // Rechercher d'abord dans la sauvegarde locale (plus rapide)
      final backupContact = await _backupService.searchByName(contactName);
      
      if (backupContact != null && backupContact.phoneNumbers.isNotEmpty) {
        final phoneNumber = backupContact.phoneNumbers.first;
        _commandResponseController.add(_t('contact_found', [backupContact.displayName]));
        _commandResponseController.add(_t('calling_in_progress'));
        
        // Lancer l'appel
        await _makePhoneCall(phoneNumber);
        return;
      }
      
      // Si pas trouvé dans la sauvegarde, chercher dans les contacts du téléphone
      final phoneNumber = await _contactService.findPhoneByName(contactName);

      if (phoneNumber == null) {
        _commandResponseController.add(_t('contact_not_found', [contactName]));
        _commandResponseController.add(_t('check_name_pronunciation'));
        return;
      }

      _commandResponseController.add(_t('calling_contact', [contactName]));

      // Lancer l'appel
      await _makePhoneCall(phoneNumber);
    } catch (e) {
      _errorController.add(_t('call_error', [e.toString()]));
      _commandResponseController.add(_t('cannot_call_contact', [contactName]));
    }
  }

  /// Lance un appel téléphonique
  Future<void> _makePhoneCall(String phoneNumber) async {
    try {
      // Nettoyer le numéro de téléphone
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      debugPrint('📞 Tentative d\'appel vers: $cleanedNumber (original: $phoneNumber)');
      
      final Uri url = Uri(scheme: 'tel', path: cleanedNumber);
      debugPrint('📞 URI d\'appel: $url');
      
      final canLaunch = await canLaunchUrl(url);
      debugPrint('📞 canLaunchUrl: $canLaunch');
      
      if (canLaunch) {
        debugPrint('📞 Lancement de l\'appel...');
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('📞 Appel lancé avec succès!');
      } else {
        debugPrint('❌ Impossible de lancer l\'appel - canLaunchUrl retourne false');
        throw Exception(_t('cannot_launch_call', [phoneNumber]));
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du lancement de l\'appel: $e');
      throw e;
    }
  }

  /// Vérifie si le service est en train d'écouter
  bool get isListening => _speechService.isListening;

  /// Libère les ressources
  void dispose() {
    _speechService.dispose();
    _listeningStateController.close();
    _recognizedTextController.close();
    _commandResponseController.close();
    _errorController.close();
  }
} 