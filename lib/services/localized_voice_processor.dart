import 'package:flutter/material.dart';
import '../config/app_localizations.dart';
import 'voice_command_processor.dart';

/// Extension du VoiceCommandProcessor qui utilise les traductions
class LocalizedVoiceProcessor {
  final VoiceCommandProcessor _processor;
  final BuildContext context;
  
  LocalizedVoiceProcessor(this.context) : _processor = VoiceCommandProcessor();
  
  /// Traduit un message avec le contexte actuel
  String _t(String key, [List<String>? params]) {
    return AppLocalizations.of(context)?.translate(key, params) ?? key;
  }
  
  /// Initialise le service avec des messages traduits
  Future<void> initialize() async {
    await _processor.initialize();
    
    // Les messages d'erreur sont déjà gérés par le processeur de base
    // mais nous pourrions ajouter des traductions supplémentaires ici
  }
  
  /// Démarre l'écoute vocale
  Future<void> startListening() => _processor.startListening();
  
  /// Arrête l'écoute vocale
  Future<void> stopListening() => _processor.stopListening();
  
  /// Vérifie si le service est en train d'écouter
  bool get isListening => _processor.isListening;
  
  /// Streams d'événements
  Stream<bool> get listeningStateStream => _processor.listeningStateStream;
  Stream<String> get recognizedTextStream => _processor.recognizedTextStream;
  Stream<String> get commandResponseStream => _processor.commandResponseStream;
  Stream<String> get errorStream => _processor.errorStream;
  
  /// Libère les ressources
  void dispose() => _processor.dispose();
}