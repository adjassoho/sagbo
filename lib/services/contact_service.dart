import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'fongbe_translation_service.dart';

/// Service de gestion des contacts du téléphone
class ContactService {
  // Singleton pattern
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  // Cache des contacts
  List<Contact>? _contacts;

  // Service de traduction
  final FongbeTranslationService _translationService = FongbeTranslationService();

  /// Vérifie si les permissions de contacts sont accordées
  Future<bool> checkContactsPermission() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      return true;
    }
    
    // Demander la permission si elle n'est pas déjà accordée
    final result = await Permission.contacts.request();
    return result.isGranted;
  }

  /// Charge tous les contacts du téléphone
  Future<List<Contact>> getContacts({bool forceRefresh = false}) async {
    // Retourner le cache si disponible et pas de forçage
    if (!forceRefresh && _contacts != null) {
      return _contacts!;
    }

    // Vérifier la permission
    if (await checkContactsPermission()) {
      try {
        // Charger les contacts
        _contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
          withThumbnail: false,
          withAccounts: false,
        );
        return _contacts ?? [];
      } catch (e) {
        debugPrint('Erreur lors du chargement des contacts: $e');
        return [];
      }
    } else {
      debugPrint('Permission de contacts refusée');
      return [];
    }
  }

  /// Recherche un contact par son nom (exacte ou approximative)
  Future<Contact?> findContactByName(String name, {double threshold = 0.7}) async {
    final contacts = await getContacts();
    final normalizedName = _normalizeName(name);
    
    // Premier essai: correspondance exacte
    try {
      final exactMatch = contacts.firstWhere((contact) {
        final contactFullName = '${contact.name.first} ${contact.name.last}'.toLowerCase();
        final contactFirstName = _normalizeName(contact.name.first);
        final contactLastName = _normalizeName(contact.name.last);
        
        return contactFullName.contains(normalizedName) || 
               contactFirstName.contains(normalizedName) ||
               contactLastName.contains(normalizedName);
      });
      
      return exactMatch;
    } catch (e) {
      // Pas de correspondance exacte, essayer approximative
      Contact? bestMatch;
      double bestScore = threshold;
      
      for (final contact in contacts) {
        final firstName = _normalizeName(contact.name.first);
        final lastName = _normalizeName(contact.name.last);
        
        final firstNameScore = _calculateSimilarity(normalizedName, firstName);
        final lastNameScore = _calculateSimilarity(normalizedName, lastName);
        
        final score = firstNameScore > lastNameScore ? firstNameScore : lastNameScore;
        
        if (score > bestScore) {
          bestScore = score;
          bestMatch = contact;
        }
      }
      
      return bestMatch;
    }
  }

  /// Recherche le numéro de téléphone d'un contact en fonction d'un nom en fongbé ou en français
  Future<String?> findPhoneByName(String name) async {
    // Essayer de traduire le nom si c'est en fongbé
    final translatedName = _translationService.translateToFrench(name);
    
    // Chercher le contact
    final contact = await findContactByName(translatedName);
    
    if (contact != null && contact.phones.isNotEmpty) {
      return contact.phones.first.number;
    }
    
    return null;
  }

  /// Calcule la similarité entre deux chaînes (distance de Levenshtein simplifiée)
  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;
    
    // Implémentation simple de similarité
    int matches = 0;
    final minLength = s1.length < s2.length ? s1.length : s2.length;
    
    for (int i = 0; i < minLength; i++) {
      if (s1[i] == s2[i]) matches++;
    }
    
    return matches / (s1.length > s2.length ? s1.length : s2.length);
  }

  /// Normalise un nom pour la recherche (minuscules, sans accents)
  String _normalizeName(String name) {
    return name.toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ô', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ç', 'c')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i');
  }
  
  /// Vide le cache des contacts
  void clearCache() {
    _contacts = null;
  }
} 