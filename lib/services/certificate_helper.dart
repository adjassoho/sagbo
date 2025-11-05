import 'dart:io';
import 'package:flutter/foundation.dart';

/// Cette classe permet de contourner les erreurs de certificat SSL
/// À utiliser uniquement en développement ou si l'API est sécurisée par d'autres moyens
class SagboCertificateHelper extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    // Configuration pour contourner les problèmes SSL/TLS
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      debugPrint('Certificat SSL ignoré pour $host:$port');
      return true; // Accepter tous les certificats
    };

    // Configuration additionnelle pour les problèmes TLS
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 30);

    return client;
  }
}
