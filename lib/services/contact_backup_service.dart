import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:path_provider/path_provider.dart';
import 'contact_service.dart';

/// Structure d'un contact sauvegardé
class BackupContact {
  final String id;
  final String displayName;
  final String firstName;
  final String lastName;
  final List<String> phoneNumbers;
  final List<String> normalizedNames;
  final DateTime lastUpdated;
  
  BackupContact({
    required this.id,
    required this.displayName,
    required this.firstName,
    required this.lastName,
    required this.phoneNumbers,
    required this.normalizedNames,
    required this.lastUpdated,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumbers': phoneNumbers,
    'normalizedNames': normalizedNames,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
  
  factory BackupContact.fromJson(Map<String, dynamic> json) => BackupContact(
    id: json['id'],
    displayName: json['displayName'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    phoneNumbers: List<String>.from(json['phoneNumbers']),
    normalizedNames: List<String>.from(json['normalizedNames']),
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );
}

/// Service de sauvegarde et synchronisation des contacts
/// Crée un répertoire parallèle local pour un accès rapide
class ContactBackupService {
  static final ContactBackupService _instance = ContactBackupService._internal();
  factory ContactBackupService() => _instance;
  ContactBackupService._internal();

  final ContactService _contactService = ContactService();
  
  // Nom du fichier de sauvegarde
  static const String _backupFileName = 'contacts_backup.json';
  
  /// Obtient le chemin du fichier de sauvegarde
  Future<String> get _backupFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_backupFileName';
  }
  
  /// Synchronise les contacts du téléphone avec la sauvegarde locale
  Future<void> syncContacts() async {
    try {
      debugPrint('🔄 Début de la synchronisation des contacts...');
      
      // Récupérer tous les contacts du téléphone
      final contacts = await _contactService.getContacts(forceRefresh: true);
      debugPrint('📱 ${contacts.length} contacts trouvés sur le téléphone');
      
      // Convertir en format de sauvegarde
      final backupContacts = <BackupContact>[];
      
      for (final contact in contacts) {
        if (contact.phones.isEmpty) continue; // Ignorer les contacts sans numéro
        
        final phoneNumbers = contact.phones
            .map((phone) => _normalizePhoneNumber(phone.number))
            .toList();
        
        // Créer plusieurs variantes du nom pour la recherche
        final normalizedNames = _generateNameVariants(
          contact.name.first,
          contact.name.last,
          contact.displayName,
        );
        
        backupContacts.add(BackupContact(
          id: contact.id,
          displayName: contact.displayName,
          firstName: contact.name.first,
          lastName: contact.name.last,
          phoneNumbers: phoneNumbers,
          normalizedNames: normalizedNames,
          lastUpdated: DateTime.now(),
        ));
      }
      
      // Sauvegarder dans le fichier
      await _saveBackup(backupContacts);
      debugPrint('✅ ${backupContacts.length} contacts sauvegardés');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la synchronisation: $e');
    }
  }
  
  /// Génère des variantes de noms pour améliorer la recherche
  List<String> _generateNameVariants(String firstName, String lastName, String displayName) {
    final variants = <String>{};
    
    // Ajouter le nom complet
    if (displayName.isNotEmpty) {
      variants.add(_normalizeForSearch(displayName));
    }
    
    // Prénom seul
    if (firstName.isNotEmpty) {
      variants.add(_normalizeForSearch(firstName));
    }
    
    // Nom seul
    if (lastName.isNotEmpty) {
      variants.add(_normalizeForSearch(lastName));
    }
    
    // Combinaisons
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      variants.add(_normalizeForSearch('$firstName $lastName'));
      variants.add(_normalizeForSearch('$lastName $firstName'));
    }
    
    // Ajouter des variantes sans accents
    variants.addAll(variants.map((v) => _removeAccents(v)).toSet());
    
    return variants.toList();
  }
  
  /// Normalise un nom pour la recherche
  String _normalizeForSearch(String name) {
    return name.toLowerCase().trim();
  }
  
  /// Supprime les accents d'une chaîne
  String _removeAccents(String text) {
    return text
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i');
  }
  
  /// Normalise un numéro de téléphone
  String _normalizePhoneNumber(String phoneNumber) {
    // Supprimer tous les caractères non numériques sauf le +
    String normalized = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Ajouter le préfixe du pays si nécessaire (ex: Bénin +229)
    if (!normalized.startsWith('+') && normalized.length >= 8) {
      // Si c'est un numéro local, ajouter le code pays du Bénin
      if (normalized.length == 8) {
        normalized = '+229$normalized';
      }
    }
    
    return normalized;
  }
  
  /// Sauvegarde les contacts dans un fichier
  Future<void> _saveBackup(List<BackupContact> contacts) async {
    try {
      final file = File(await _backupFilePath);
      final data = {
        'version': '1.0',
        'lastSync': DateTime.now().toIso8601String(),
        'contactCount': contacts.length,
        'contacts': contacts.map((c) => c.toJson()).toList(),
      };
      
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
    }
  }
  
  /// Charge les contacts depuis la sauvegarde
  Future<List<BackupContact>> loadBackup() async {
    try {
      final file = File(await _backupFilePath);
      
      if (!await file.exists()) {
        debugPrint('⚠️ Aucune sauvegarde trouvée');
        return [];
      }
      
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      final contacts = (data['contacts'] as List)
          .map((json) => BackupContact.fromJson(json))
          .toList();
      
      debugPrint('📂 ${contacts.length} contacts chargés depuis la sauvegarde');
      return contacts;
      
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la sauvegarde: $e');
      return [];
    }
  }
  
  /// Recherche rapide dans la sauvegarde par nom
  Future<BackupContact?> searchByName(String searchName) async {
    final normalizedSearch = _normalizeForSearch(searchName);
    final contacts = await loadBackup();
    
    // Recherche exacte d'abord
    for (final contact in contacts) {
      for (final variant in contact.normalizedNames) {
        if (variant.contains(normalizedSearch)) {
          return contact;
        }
      }
    }
    
    // Recherche approximative si pas de résultat exact
    BackupContact? bestMatch;
    double bestScore = 0.7; // Seuil minimum
    
    for (final contact in contacts) {
      for (final variant in contact.normalizedNames) {
        final score = _calculateSimilarity(normalizedSearch, variant);
        if (score > bestScore) {
          bestScore = score;
          bestMatch = contact;
        }
      }
    }
    
    return bestMatch;
  }
  
  /// Calcule la similarité entre deux chaînes
  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;
    
    // Distance de Levenshtein simplifiée
    int matches = 0;
    final minLength = s1.length < s2.length ? s1.length : s2.length;
    
    for (int i = 0; i < minLength; i++) {
      if (s1[i] == s2[i]) matches++;
    }
    
    // Bonus si l'un contient l'autre
    if (s1.contains(s2) || s2.contains(s1)) {
      matches += minLength ~/ 2;
    }
    
    return matches / (s1.length > s2.length ? s1.length : s2.length);
  }
  
  /// Obtient l'état de la dernière synchronisation
  Future<Map<String, dynamic>?> getSyncStatus() async {
    try {
      final file = File(await _backupFilePath);
      if (!await file.exists()) return null;
      
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      return {
        'lastSync': DateTime.parse(data['lastSync']),
        'contactCount': data['contactCount'],
        'version': data['version'],
      };
    } catch (e) {
      return null;
    }
  }
  
  /// Synchronise automatiquement si nécessaire
  Future<void> autoSync() async {
    final status = await getSyncStatus();
    
    // Synchroniser si jamais fait ou si dernière sync > 24h
    if (status == null || 
        DateTime.now().difference(status['lastSync']).inHours > 24) {
      await syncContacts();
    }
  }
}
