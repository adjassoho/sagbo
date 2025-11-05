import 'dart:io';
import 'package:http/http.dart' as http;

/// Récupérer la documentation complète de l'API
void main() async {
  print('📖 RÉCUPÉRATION DOCUMENTATION API FONGBÉ');
  print('==========================================');
  
  try {
    final response = await http.get(
      Uri.parse('https://fongbe.work.gd'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'fr-FR,fr;q=0.9,en;q=0.8',
      },
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      print('✅ Page récupérée avec succès');
      print('📄 Contenu complet:');
      print('=' * 50);
      print(response.body);
      print('=' * 50);
    } else {
      print('❌ Erreur: ${response.statusCode}');
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
