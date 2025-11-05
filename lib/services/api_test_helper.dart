import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Helper pour tester la connectivité de l'API Fongbe
class ApiTestHelper {
  static const List<String> testUrls = [
    'http://fongbe.work.gd/api/health',
    'https://fongbe.work.gd/api/health',
  ];

  /// Teste toutes les URLs et retourne la première qui fonctionne
  static Future<String?> findWorkingApiUrl() async {
    for (String url in testUrls) {
      try {
        debugPrint('Test de connectivité: $url');
        
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        client.connectionTimeout = const Duration(seconds: 10);
        
        final response = await http.get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));
        
        client.close();
        
        if (response.statusCode == 200) {
          final apiUrl = url.replaceAll('/health', '/transcribe/');
          debugPrint('✅ API accessible via: $apiUrl');
          return apiUrl;
        } else {
          debugPrint('❌ $url retourne: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Erreur avec $url: $e');
      }
    }
    
    debugPrint('⚠️ Aucune URL d\'API accessible');
    return null;
  }

  /// Teste spécifiquement la connectivité réseau
  static Future<bool> testNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Pas de connectivité réseau: $e');
      return false;
    }
  }

  /// Diagnostic complet de connectivité
  static Future<Map<String, dynamic>> runDiagnostic() async {
    final diagnostic = <String, dynamic>{};
    
    // Test de connectivité réseau
    diagnostic['network'] = await testNetworkConnectivity();
    
    // Test des URLs d'API
    diagnostic['workingApiUrl'] = await findWorkingApiUrl();
    
    // Informations système
    diagnostic['platform'] = Platform.operatingSystem;
    diagnostic['timestamp'] = DateTime.now().toIso8601String();
    
    return diagnostic;
  }
}
