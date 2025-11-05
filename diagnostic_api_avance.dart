import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Diagnostic avancé pour identifier le problème exact avec l'API Fongbé
void main() async {
  print('🔬 DIAGNOSTIC AVANCÉ API FONGBÉ');
  print('================================');
  
  // Configuration du client HTTP avec options avancées
  final client = HttpClient();
  client.badCertificateCallback = (cert, host, port) => true;
  client.connectionTimeout = const Duration(seconds: 30);
  client.idleTimeout = const Duration(seconds: 30);
  
  // URLs à tester avec différentes variations
  final urls = [
    'https://fongbe.work.gd',
    'http://fongbe.work.gd',
    'https://www.fongbe.work.gd',
    'http://www.fongbe.work.gd',
    'https://fongbe.work.gd:443',
    'http://fongbe.work.gd:80',
    'https://fongbe.work.gd/api',
    'https://fongbe.work.gd/api/transcribe',
    'https://fongbe.work.gd/api/transcribe/',
  ];
  
  for (String url in urls) {
    await testUrlAdvanced(url);
  }
  
  // Test de résolution DNS
  await testDnsResolution();
  
  // Test avec différents User-Agents
  await testWithDifferentUserAgents();
  
  client.close();
  print('\n✅ Diagnostic terminé');
}

Future<void> testUrlAdvanced(String url) async {
  print('\n🧪 Test avancé de: $url');
  
  try {
    // Test 1: Ping/Connectivité de base
    final uri = Uri.parse(url);
    print('   Host: ${uri.host}');
    print('   Port: ${uri.port}');
    print('   Scheme: ${uri.scheme}');
    
    // Test 2: Requête GET avec timeout étendu
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': '*/*',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    ).timeout(const Duration(seconds: 30));
    
    print('   ✅ Statut: ${response.statusCode}');
    print('   📋 Headers: ${response.headers}');
    print('   📄 Contenu (200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
    
    // Si c'est un endpoint API, tester POST
    if (url.contains('transcribe')) {
      await testPostRequest(url);
    }
    
  } catch (e) {
    print('   ❌ Erreur: $e');
    
    // Analyser le type d'erreur
    if (e.toString().contains('SocketException')) {
      print('   🔍 Type: Problème de réseau/DNS');
    } else if (e.toString().contains('TimeoutException')) {
      print('   🔍 Type: Timeout de connexion');
    } else if (e.toString().contains('HandshakeException')) {
      print('   🔍 Type: Problème SSL/TLS');
    } else if (e.toString().contains('HttpException')) {
      print('   🔍 Type: Erreur HTTP');
    }
  }
}

Future<void> testPostRequest(String url) async {
  print('   🔄 Test POST multipart...');
  
  try {
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll({
      'User-Agent': 'SagboApp/1.0',
      'Accept': 'application/json',
      'Content-Type': 'multipart/form-data',
    });

    // Ajouter un fichier audio factice
    request.files.add(http.MultipartFile.fromString(
      'file',
      'fake audio data for testing',
      filename: 'test.wav',
    ));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    print('   ✅ POST Statut: ${response.statusCode}');
    print('   📋 POST Headers: ${response.headers}');
    print('   📄 POST Réponse: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
    
  } catch (e) {
    print('   ❌ POST Erreur: $e');
  }
}

Future<void> testDnsResolution() async {
  print('\n🌐 Test de résolution DNS...');
  
  try {
    final addresses = await InternetAddress.lookup('fongbe.work.gd');
    print('   ✅ Adresses IP trouvées:');
    for (var addr in addresses) {
      print('     - ${addr.address} (${addr.type})');
    }
  } catch (e) {
    print('   ❌ Erreur DNS: $e');
  }
}

Future<void> testWithDifferentUserAgents() async {
  print('\n🤖 Test avec différents User-Agents...');
  
  final userAgents = [
    'SagboApp/1.0',
    'Mozilla/5.0 (Android 10; Mobile; rv:81.0) Gecko/81.0 Firefox/81.0',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
    'curl/7.68.0',
    'PostmanRuntime/7.26.8',
  ];
  
  for (String userAgent in userAgents) {
    try {
      final response = await http.get(
        Uri.parse('https://fongbe.work.gd'),
        headers: {'User-Agent': userAgent},
      ).timeout(const Duration(seconds: 10));
      
      print('   ✅ $userAgent: ${response.statusCode}');
    } catch (e) {
      print('   ❌ $userAgent: $e');
    }
  }
}
