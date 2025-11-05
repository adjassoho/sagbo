import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Recherche systématique du vrai endpoint de l'API
void main() async {
  print('🔍 RECHERCHE DU VRAI ENDPOINT API FONGBÉ');
  print('=========================================');
  
  // Endpoints possibles basés sur les conventions d'API
  final endpoints = [
    // Endpoints standards
    '/api/transcribe',
    '/api/transcribe/',
    '/api/v1/transcribe',
    '/api/v1/transcribe/',
    '/transcribe',
    '/transcribe/',
    '/upload',
    '/upload/',
    '/speech',
    '/speech/',
    '/recognize',
    '/recognize/',
    '/asr',
    '/asr/',
    
    // Endpoints spécifiques Fongbé
    '/fongbe/transcribe',
    '/fongbe/transcribe/',
    '/fongbe',
    '/fongbe/',
    
    // Endpoints de test
    '/test',
    '/test/',
    '/health',
    '/status',
    '/ping',
  ];
  
  final baseUrl = 'https://fongbe.work.gd';
  
  for (String endpoint in endpoints) {
    await testEndpoint('$baseUrl$endpoint');
  }
  
  // Tester aussi avec HTTP
  print('\n🔄 Test avec HTTP...');
  final httpBaseUrl = 'http://fongbe.work.gd';
  
  // Tester seulement les endpoints les plus prometteurs avec HTTP
  final priorityEndpoints = [
    '/api/transcribe/',
    '/transcribe/',
    '/upload/',
    '/speech/',
  ];
  
  for (String endpoint in priorityEndpoints) {
    await testEndpoint('$httpBaseUrl$endpoint');
  }
  
  print('\n✅ Recherche terminée');
}

Future<void> testEndpoint(String url) async {
  print('\n🧪 Test: $url');
  
  try {
    // Test 1: GET pour voir si l'endpoint existe
    try {
      final getResponse = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SagboApp/1.0',
          'Accept': 'application/json, text/html',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('   GET → ${getResponse.statusCode}');
      
      if (getResponse.statusCode == 200) {
        print('   📄 Contenu: ${getResponse.body.substring(0, getResponse.body.length > 200 ? 200 : getResponse.body.length)}');
      } else if (getResponse.statusCode == 405) {
        print('   ✅ Méthode non autorisée (GET) - L\'endpoint existe probablement !');
      } else if (getResponse.statusCode == 404) {
        print('   ❌ Non trouvé');
        return; // Pas la peine de tester POST si GET retourne 404
      }
      
    } catch (e) {
      print('   GET → Erreur: $e');
      return; // Si GET échoue, POST échouera probablement aussi
    }
    
    // Test 2: POST pour voir si c'est un endpoint d'upload
    try {
      final postResponse = await http.post(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SagboApp/1.0',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'test': 'data'}),
      ).timeout(const Duration(seconds: 10));
      
      print('   POST → ${postResponse.statusCode}');
      
      if (postResponse.statusCode == 200 || postResponse.statusCode == 400 || 
          postResponse.statusCode == 422) {
        print('   ✅ ENDPOINT TROUVÉ ! Répond aux requêtes POST');
        print('   📄 Réponse: ${postResponse.body}');
      }
      
    } catch (e) {
      print('   POST → Erreur: $e');
    }
    
    // Test 3: POST multipart (le vrai test pour upload de fichier)
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll({
        'User-Agent': 'SagboApp/1.0',
        'Accept': 'application/json',
      });

      // Ajouter un fichier factice
      request.files.add(http.MultipartFile.fromString(
        'file',
        'test audio data',
        filename: 'test.wav',
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      print('   MULTIPART → ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 400 || 
          response.statusCode == 422) {
        print('   🎯 ENDPOINT D\'UPLOAD TROUVÉ !');
        print('   📄 Réponse: ${response.body}');
      }
      
    } catch (e) {
      print('   MULTIPART → Erreur: $e');
    }
    
  } catch (e) {
    print('   ❌ Erreur générale: $e');
  }
}
