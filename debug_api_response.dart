import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Diagnostic approfondi de la réponse API
void main() async {
  print('🔬 DIAGNOSTIC APPROFONDI DE L\'API');
  print('===================================');
  
  await analyzeApiResponse();
  
  print('\n✅ Diagnostic terminé');
}

Future<void> analyzeApiResponse() async {
  try {
    // Créer un fichier WAV valide (on sait que ça marche)
    final tempDir = Directory.systemTemp;
    final wavFile = File('${tempDir.path}/debug_test.wav');
    
    final wavData = createOptimalWavFile();
    await wavFile.writeAsBytes(wavData);
    
    print('📁 Fichier WAV créé: ${await wavFile.length()} octets');
    
    // Tester avec différentes configurations
    await testWithDifferentHeaders(wavFile);
    await testWithDifferentUrls(wavFile);
    await testWithDifferentFieldNames(wavFile);
    
    await wavFile.delete();
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

Future<void> testWithDifferentHeaders(File wavFile) async {
  print('\n🔧 TEST AVEC DIFFÉRENTS HEADERS:');
  
  final headerConfigs = [
    {
      'name': 'Configuration 1 - Basique',
      'headers': {
        'Accept': 'application/json',
        'User-Agent': 'SagboApp/1.0',
      }
    },
    {
      'name': 'Configuration 2 - Explicite',
      'headers': {
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
        'User-Agent': 'SagboApp/1.0',
        'Connection': 'keep-alive',
      }
    },
    {
      'name': 'Configuration 3 - Navigateur',
      'headers': {
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Origin': 'https://fongbe.work.gd',
        'Referer': 'https://fongbe.work.gd/',
      }
    },
    {
      'name': 'Configuration 4 - API Pure',
      'headers': {
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
        'User-Agent': 'Dart/3.0 (dart:io)',
      }
    },
  ];
  
  for (var config in headerConfigs) {
    print('\n   ${config['name']}:');
    await testApiCall(wavFile, config['headers'] as Map<String, String>);
  }
}

Future<void> testWithDifferentUrls(File wavFile) async {
  print('\n🌐 TEST AVEC DIFFÉRENTES URLs:');
  
  final urls = [
    'https://fongbe.work.gd/api/transcribe/',
    'https://fongbe.work.gd/api/transcribe',
    'https://fongbe.work.gd/transcribe/',
    'https://fongbe.work.gd/transcribe',
    'http://fongbe.work.gd/api/transcribe/',
  ];
  
  final headers = {
    'Accept': 'application/json',
    'User-Agent': 'SagboApp/1.0',
  };
  
  for (String url in urls) {
    print('\n   URL: $url');
    await testApiCallWithUrl(wavFile, url, headers);
  }
}

Future<void> testWithDifferentFieldNames(File wavFile) async {
  print('\n📝 TEST AVEC DIFFÉRENTS NOMS DE CHAMPS:');
  
  final fieldNames = ['file', 'audio', 'audioFile', 'upload', 'data'];
  final headers = {
    'Accept': 'application/json',
    'User-Agent': 'SagboApp/1.0',
  };
  
  for (String fieldName in fieldNames) {
    print('\n   Champ: $fieldName');
    await testApiCallWithField(wavFile, fieldName, headers);
  }
}

Future<void> testApiCall(File wavFile, Map<String, String> headers) async {
  await testApiCallWithUrl(wavFile, 'https://fongbe.work.gd/api/transcribe/', headers);
}

Future<void> testApiCallWithUrl(File wavFile, String url, Map<String, String> headers) async {
  await testApiCallWithField(wavFile, 'file', headers, url: url);
}

Future<void> testApiCallWithField(File wavFile, String fieldName, Map<String, String> headers, {String? url}) async {
  try {
    final apiUrl = url ?? 'https://fongbe.work.gd/api/transcribe/';
    final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    
    // Ajouter les headers (sans Content-Type car multipart l'ajoute automatiquement)
    final cleanHeaders = Map<String, String>.from(headers);
    cleanHeaders.remove('Content-Type');
    request.headers.addAll(cleanHeaders);

    final multipartFile = await http.MultipartFile.fromPath(
      fieldName,
      wavFile.path,
      filename: 'audio.wav',
      contentType: MediaType('audio', 'wav'),
    );
    request.files.add(multipartFile);

    print('      📤 Envoi...');
    final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamedResponse);

    print('      📊 Statut: ${response.statusCode}');
    print('      📋 Content-Type: ${response.headers['content-type']}');
    print('      📏 Taille: ${response.body.length} caractères');
    
    // Analyser le contenu de la réponse
    if (response.body.trim().startsWith('{') || response.body.trim().startsWith('[')) {
      print('      ✅ Semble être du JSON');
      try {
        final json = jsonDecode(response.body);
        print('      🎯 JSON parsé: $json');
      } catch (e) {
        print('      ⚠️ Erreur parsing JSON: $e');
        print('      📄 Début: ${response.body.substring(0, min(200, response.body.length))}');
      }
    } else if (response.body.toLowerCase().contains('<!doctype') || 
               response.body.toLowerCase().contains('<html')) {
      print('      ❌ C\'est du HTML');
      print('      📄 Début: ${response.body.substring(0, min(200, response.body.length))}');
      
      // Chercher des indices dans le HTML
      if (response.body.contains('error') || response.body.contains('Error')) {
        print('      🔍 Contient "error"');
      }
      if (response.body.contains('500') || response.body.contains('Internal Server Error')) {
        print('      🔍 Erreur serveur 500');
      }
    } else {
      print('      ❓ Format inconnu');
      print('      📄 Début: ${response.body.substring(0, min(200, response.body.length))}');
    }
    
  } catch (e) {
    print('      ❌ Exception: $e');
  }
}

List<int> createOptimalWavFile() {
  // Créer un fichier WAV optimal pour la reconnaissance vocale
  const sampleRate = 16000;  // Fréquence standard pour la reconnaissance vocale
  const duration = 2;        // 2 secondes - durée raisonnable
  const numSamples = sampleRate * duration;
  const bytesPerSample = 2;  // 16-bit
  const numChannels = 1;     // Mono
  
  final dataSize = numSamples * bytesPerSample * numChannels;
  final fileSize = 44 + dataSize;
  
  // Header WAV standard
  final header = <int>[
    // RIFF header
    0x52, 0x49, 0x46, 0x46, // "RIFF"
    ...intToBytes(fileSize - 8, 4),
    0x57, 0x41, 0x56, 0x45, // "WAVE"
    
    // fmt chunk
    0x66, 0x6D, 0x74, 0x20, // "fmt "
    0x10, 0x00, 0x00, 0x00, // Chunk size (16)
    0x01, 0x00, // Audio format (PCM)
    ...intToBytes(numChannels, 2),
    ...intToBytes(sampleRate, 4),
    ...intToBytes(sampleRate * numChannels * bytesPerSample, 4),
    ...intToBytes(numChannels * bytesPerSample, 2),
    ...intToBytes(bytesPerSample * 8, 2),
    
    // data chunk
    0x64, 0x61, 0x74, 0x61, // "data"
    ...intToBytes(dataSize, 4),
  ];
  
  // Générer un signal audio réaliste (voix humaine simulée)
  final audioData = <int>[];
  final random = Random();
  
  for (int i = 0; i < numSamples; i++) {
    final time = i / sampleRate;
    
    // Simuler une voix humaine avec plusieurs harmoniques
    var sample = 0.0;
    sample += sin(2 * pi * 200 * time) * 0.3;  // Fondamentale basse
    sample += sin(2 * pi * 400 * time) * 0.4;  // Harmonique
    sample += sin(2 * pi * 600 * time) * 0.2;  // Harmonique
    sample += sin(2 * pi * 800 * time) * 0.1;  // Harmonique
    
    // Ajouter de la modulation (comme une vraie voix)
    final modulation = sin(2 * pi * 5 * time) * 0.2 + 1.0;
    sample *= modulation;
    
    // Ajouter un peu de bruit (réalisme)
    sample += (random.nextDouble() - 0.5) * 0.1;
    
    // Convertir en entier 16-bit
    final intSample = (sample * 16000).round().clamp(-32768, 32767);
    audioData.addAll(intToBytes(intSample, 2));
  }
  
  return [...header, ...audioData];
}

List<int> intToBytes(int value, int bytes) {
  final result = <int>[];
  for (int i = 0; i < bytes; i++) {
    result.add((value >> (i * 8)) & 0xFF);
  }
  return result;
}

double sin(double x) {
  while (x > pi) x -= 2 * pi;
  while (x < -pi) x += 2 * pi;
  final x2 = x * x;
  return x - (x * x2) / 6 + (x * x2 * x2) / 120;
}

const pi = 3.14159265359;
