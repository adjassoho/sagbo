import 'package:flutter/foundation.dart';

/// Service pour la traduction entre le fongbé et le français
class FongbeTranslationService {
  // Singleton pattern
  static final FongbeTranslationService _instance = FongbeTranslationService._internal();
  factory FongbeTranslationService() => _instance;
  FongbeTranslationService._internal();

  /// Alphabet fongbé
  static const List<String> fongbeAlphabet = [
    'a', 'b', 'c', 'd', 'ɖ', 'e', 'ɛ', 'f', 'g', 'gb', 'h', 'i', 'j', 'k',
    'kp', 'l', 'm', 'n', 'ny', 'o', 'ɔ', 'p', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  ];

  /// Voyelles fongbé orales et nasales
  static const List<String> fongbeVowels = [
    'a', 'e', 'ɛ', 'i', 'o', 'ɔ', 'u',  // Orales
    'an', 'ɛn', 'in', 'on', 'ɔn', 'un'  // Nasales
  ];

  /// Dictionnaire des commandes courantes
  final Map<String, String> _commandDictionary = {
    'ylɔ': 'appeler',
    'sɔ': 'prendre',
    'kplɔn': 'enseigner',
    'xlɛ': 'lire',
    'wlan': 'écrire',
    'sè': 'écouter',
  };

  /// Dictionnaire des noms communs
  final Map<String, String> _commonNounsDictionary = {
    'así': 'marché',
    'xɔ': 'maison',
    'agble': 'champ',
    'tɔ': 'père',
    'nɔ': 'mère',
    'ayi': 'terre',
    'xwe': 'année',
    'jɛ': 'sel',
    'eglí': 'église',
  };

  /// Dictionnaire des noms propres (prénoms)
  final Map<String, String> _nameDictionary = {
    // Jours de la semaine/prénoms associés
    'kɔku': 'Koku',     // Lundi
    'ajídi': 'Adjidji', // Mardi
    'sɔvɔ': 'Sogbo',    // Mercredi
    'akɔsú': 'Akossou', // Jeudi
    'axɔsú': 'Ahossou', // Vendredi
    'síkɔ': 'Siko',     // Samedi
    'aklùn': 'Aklusu',  // Dimanche
    
    // Autres prénoms courants
    'gbɛnsɔ': 'Gbesso',
    'sɔtɔ': 'Sottin',
    'kɔjɔ': 'Kodjo',
    'kɔfí': 'Kofi',
    'abɔlɔ': 'Abolo',
    'adɔkɔ': 'Adoko',
    
    // Prénoms français
    'jan': 'Jean',
    'jan-pjɛʁ': 'Jean-Pierre',
    'pɔl': 'Paul',
    'maʁi': 'Marie',
    'jozɛf': 'Joseph',
    'piɛʁ': 'Pierre',
    'antuwan': 'Antoine',
    'filip': 'Philippe'
  };

  /// Traduit un mot du fongbé vers le français
  String translateToFrench(String fongbeWord) {
    // Normaliser le mot en supprimant les tons et en minuscule
    final normalized = _normalizeFongbeWord(fongbeWord.toLowerCase());
    
    // Vérifier dans les dictionnaires
    if (_commandDictionary.containsKey(normalized)) {
      return _commandDictionary[normalized]!;
    } 
    
    if (_commonNounsDictionary.containsKey(normalized)) {
      return _commonNounsDictionary[normalized]!;
    }
    
    if (_nameDictionary.containsKey(normalized)) {
      return _nameDictionary[normalized]!;
    }
    
    // Si pas de correspondance, retourner le mot d'origine
    return fongbeWord;
  }
  
  /// Détecte la langue d'entrée (fongbé ou français)
  bool isFongbe(String text) {
    // Compter les caractères spécifiques au fongbé
    int fongbeSpecificChars = 0;
    
    for (var char in text.runes) {
      final s = String.fromCharCode(char);
      if (s == 'ɛ' || s == 'ɔ' || s == 'ɖ' || s == 'ŋ') {
        fongbeSpecificChars++;
      }
    }
    
    // Vérifier les combinaisons spécifiques
    if (text.contains('gb') || text.contains('kp') || text.contains('ny')) {
      fongbeSpecificChars++;
    }
    
    // Détecter si les combinaisons de lettres sont typiques du fongbé
    // Plus de 2 caractères spécifiques au fongbé ou 20% du texte
    return fongbeSpecificChars > 2 || fongbeSpecificChars / text.length > 0.2;
  }
  
  /// Normalise un mot fongbé en supprimant les tons
  String _normalizeFongbeWord(String word) {
    // Supprimer les signes diacritiques des tons
    return word
      .replaceAll('à', 'a').replaceAll('á', 'a')
      .replaceAll('è', 'e').replaceAll('é', 'e')
      .replaceAll('ì', 'i').replaceAll('í', 'i')
      .replaceAll('ò', 'o').replaceAll('ó', 'o')
      .replaceAll('ù', 'u').replaceAll('ú', 'u')
      .replaceAll('ɛ̀', 'ɛ').replaceAll('ɛ́', 'ɛ')
      .replaceAll('ɔ̀', 'ɔ').replaceAll('ɔ́', 'ɔ');
  }

  /// Analyse une commande vocale en fongbé pour détecter une demande d'appel
  /// et extraire le nom du contact
  /// 
  /// Formats acceptés: "ylɔ [nom]", "yolo [nom]", "ɔlɔ [nom]", "yɔlɔ [nom]", etc.
  /// La logique détecte "lɔ" ou "lo" précédé de n'importe quelle voyelle
  Map<String, String?> parseVoiceCommand(String command) {
    final normalizedCommand = command.toLowerCase();
    
    // Recherche flexible de la commande d'appel
    // On cherche "lɔ " ou "lo " précédé d'une ou plusieurs lettres
    // Inclure aussi les espaces possibles entre les lettres
    final callPattern = RegExp(r'^[a-zA-Zɔɛŋɖ\s]*[ɔo]l[ɔo]\s+(.+)$');
    final match = callPattern.firstMatch(normalizedCommand);
    
    if (match != null) {
      // Extraire le nom après "lɔ" ou "lo"
      final name = match.group(1)?.trim();
      
      if (name != null && name.isNotEmpty) {
        // Traduire le nom si nécessaire
        final translatedName = translateToFrench(name);
        debugPrint('Commande d\'appel détectée: "$normalizedCommand"');
        debugPrint('Nom extrait: "$name" -> "$translatedName"');
        
        return {
          'command': 'call',
          'parameter': translatedName
        };
      }
    }
    
    // Vérifier aussi les variantes sans espace après lɔ/lo
    // Par exemple: "yololuc" -> appeler "luc"
    final compactPattern = RegExp(r'^[a-zA-Zɔɛŋɖ]*l[ɔo]([a-zA-Zɔɛŋɖ]+)$');
    final compactMatch = compactPattern.firstMatch(normalizedCommand);
    
    if (compactMatch != null) {
      final name = compactMatch.group(1)?.trim();
      
      if (name != null && name.isNotEmpty) {
        final translatedName = translateToFrench(name);
        debugPrint('Commande d\'appel compacte détectée: "$normalizedCommand"');
        debugPrint('Nom extrait: "$name" -> "$translatedName"');
        
        return {
          'command': 'call',
          'parameter': translatedName
        };
      }
    }
    
    // Ajouter d'autres types de commandes ici
    
    // Commande non reconnue
    debugPrint('Commande non reconnue: "$normalizedCommand"');
    return {
      'command': null,
      'parameter': null
    };
  }

  /// Récupère un dictionnaire complet de mots fongbé vers français
  Map<String, String> getFullDictionary() {
    // Combiner tous les dictionnaires
    final combinedDict = <String, String>{};
    combinedDict.addAll(_commandDictionary);
    combinedDict.addAll(_commonNounsDictionary);
    combinedDict.addAll(_nameDictionary);
    return combinedDict;
  }
  
  /// Charge des dictionnaires supplémentaires depuis un fichier ou une API
  Future<void> loadAdditionalDictionaries() async {
    // Implémentation future pour charger des dictionnaires externes
    try {
      // Simuler un chargement
      await Future.delayed(const Duration(milliseconds: 500));
      // Code pour charger depuis un fichier ou une API
    } catch (e) {
      debugPrint('Erreur lors du chargement des dictionnaires: $e');
    }
  }
} 