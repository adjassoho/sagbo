import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Service d'enregistrement audio optimisé pour la reconnaissance vocale
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  
  // Paramètres audio optimisés pour la reconnaissance vocale en fongbé
  static const RecordConfig recordConfig = RecordConfig(
    encoder: AudioEncoder.wav,
    bitRate: 128000, // Bitrate élevé pour meilleure qualité
    sampleRate: 16000, // 16kHz optimal pour reconnaissance vocale
    numChannels: 1, // Mono
    autoGain: true, // Gain automatique activé
    echoCancel: true, // Suppression d'écho
    noiseSuppress: true, // Suppression du bruit activée
  );

  /// Vérifie et demande les permissions nécessaires
  Future<bool> checkPermission() async {
    debugPrint('🔐 Vérification des permissions microphone...');
    
    final currentStatus = await Permission.microphone.status;
    debugPrint('   Statut actuel: $currentStatus');
    
    if (currentStatus.isGranted) {
      debugPrint('✅ Permission microphone déjà accordée');
      return true;
    }
    
    final microphoneStatus = await Permission.microphone.request();
    debugPrint('   Nouveau statut: $microphoneStatus');
    
    if (microphoneStatus.isGranted) {
      debugPrint('✅ Permission microphone accordée');
      return true;
    }
    
    debugPrint('❌ Permission microphone refusée');
    return false;
  }

  /// Démarre l'enregistrement audio
  Future<bool> startRecording() async {
    if (_isRecording) {
      debugPrint('⚠️ Enregistrement déjà en cours');
      return false;
    }

    if (!await checkPermission()) {
      debugPrint('❌ Permission microphone refusée');
      return false;
    }

    try {
      // Générer un nom de fichier unique
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${tempDir.path}/audio_record_${timestamp}.wav';
      
      debugPrint('🎤 Configuration d\'enregistrement:');
      debugPrint('   - Format: WAV PCM');
      debugPrint('   - Fréquence: 16kHz');
      debugPrint('   - Canaux: Mono');
      debugPrint('   - Gain automatique: Activé');
      debugPrint('   - Suppression bruit: Activée');
      debugPrint('   - Suppression écho: Activée');
      debugPrint('   - Chemin: $_currentRecordingPath');

      // Démarrer l'enregistrement
      await _recorder.start(recordConfig, path: _currentRecordingPath!);
      
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      
      debugPrint('✅ Enregistrement démarré avec succès');
      return true;
      
    } catch (e) {
      debugPrint('❌ Erreur lors du démarrage de l\'enregistrement: $e');
      _isRecording = false;
      return false;
    }
  }

  /// Arrête l'enregistrement et retourne le chemin du fichier
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      debugPrint('⚠️ Aucun enregistrement en cours');
      return null;
    }

    try {
      // Calculer la durée
      final duration = _recordingStartTime != null 
          ? DateTime.now().difference(_recordingStartTime!)
          : Duration.zero;
      
      debugPrint('⏱️ Durée d\'enregistrement: ${duration.inMilliseconds}ms');
      
      // Arrêter l'enregistrement
      final path = await _recorder.stop();
      _isRecording = false;
      
      if (path == null) {
        debugPrint('❌ Aucun fichier retourné par l\'enregistreur');
        return null;
      }
      
      debugPrint('🛑 Enregistrement arrêté: $path');
      
      // Vérifier le fichier
      final file = File(path);
      if (await file.exists()) {
        final size = await file.length();
        debugPrint('📁 Taille du fichier: $size octets');
        
        if (size > 44) { // WAV header = 44 bytes
          // Appliquer le boost de volume si nécessaire
          final boostedPath = await _applyVolumeBoost(path);
          return boostedPath ?? path;
        } else {
          debugPrint('❌ Fichier audio vide ou trop petit');
          return null;
        }
      } else {
        debugPrint('❌ Fichier audio introuvable');
        return null;
      }
      
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'arrêt de l\'enregistrement: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Applique une amplification du volume au fichier audio
  Future<String?> _applyVolumeBoost(String inputPath, {double boost = 2.0}) async {
    try {
      debugPrint('🔊 Application du boost de volume (${boost}x)...');
      
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        return null;
      }
      
      final bytes = await inputFile.readAsBytes();
      if (bytes.length <= 44) {
        return null;
      }
      
      // Créer le fichier de sortie
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/audio_boosted_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // Copier le header WAV
      final header = bytes.sublist(0, 44);
      final audioData = bytes.sublist(44);
      
      // Amplifier les données audio
      final boostedData = <int>[];
      for (int i = 0; i < audioData.length; i += 2) {
        if (i + 1 < audioData.length) {
          // Lire l'échantillon 16 bits
          int sample = audioData[i] | (audioData[i + 1] << 8);
          if (sample > 32767) sample -= 65536;
          
          // Appliquer le boost avec limitation
          sample = (sample * boost).round().clamp(-32768, 32767);
          
          // Convertir en bytes
          boostedData.add(sample & 0xFF);
          boostedData.add((sample >> 8) & 0xFF);
        }
      }
      
      // Écrire le fichier
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes([...header, ...boostedData]);
      
      debugPrint('✅ Volume amplifié avec succès');
      return outputPath;
      
    } catch (e) {
      debugPrint('❌ Erreur lors du boost audio: $e');
      return null;
    }
  }

  /// Vérifie si un enregistrement est en cours
  bool get isRecording => _isRecording;

  /// Nettoie les ressources
  Future<void> dispose() async {
    if (_isRecording) {
      await stopRecording();
    }
    await _recorder.dispose();
  }
}
