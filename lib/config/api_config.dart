/// Configuration de l'API pour l'application Sagbo
class ApiConfig {
  // URLs de l'API (locale et distante)
  static const String localApiUrl = 'http://localhost:8000';
  static const String remoteApiUrl = 'https://fon.work.gd/api';
  static const String fallbackApiUrl = 'http://fon.work.gd/api';
  
  // Endpoint pour la transcription
  static const String transcribeEndpoint = '/transcribe/';
  
  // Timeout pour les requêtes
  static const Duration requestTimeout = Duration(seconds: 30);
  
  // Configuration audio
  static const int audioSampleRate = 16000; // 16kHz
  static const int audioBitRate = 256000;  // Pour WAV
  static const int audioChannels = 1;      // Mono
  
  // Taille minimale du fichier audio (en octets)
  static const int minAudioFileSize = 10000; // ~0.5 seconde de WAV
  
  // Messages d'erreur personnalisés
  static const Map<String, String> errorMessages = {
    'no_audio': 'Aucun fichier audio fourni',
    'file_too_small': 'Enregistrement trop court',
    'transcription_failed': 'Échec de la transcription',
    'api_unavailable': 'Service temporairement indisponible',
    'network_error': 'Problème de connexion réseau',
  };
}
