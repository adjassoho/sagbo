import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestionnaire de langue pour l'application Sagbo
/// Permet de changer entre Français et Fongbé
class LanguageManager extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'fr';
  
  String _currentLanguage = _defaultLanguage;
  
  String get currentLanguage => _currentLanguage;
  
  Locale get currentLocale {
    switch (_currentLanguage) {
      case 'fon':
        return const Locale('fon', 'BJ');
      case 'fr':
      default:
        return const Locale('fr', 'FR');
    }
  }
  
  /// Initialise le gestionnaire de langue
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
    notifyListeners();
  }
  
  /// Change la langue de l'application
  Future<void> changeLanguage(String languageCode) async {
    if (languageCode != _currentLanguage) {
      _currentLanguage = languageCode;
      
      // Sauvegarder la préférence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      
      notifyListeners();
    }
  }
  
  /// Bascule entre Français et Fongbé
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLanguage == 'fr' ? 'fon' : 'fr';
    await changeLanguage(newLanguage);
  }
  
  /// Obtient le nom de la langue actuelle
  String get currentLanguageName {
    switch (_currentLanguage) {
      case 'fon':
        return 'Fongbé';
      case 'fr':
      default:
        return 'Français';
    }
  }
  
  /// Obtient l'icône de la langue actuelle
  String get currentLanguageFlag {
    switch (_currentLanguage) {
      case 'fon':
        return '🇧🇯'; // Drapeau du Bénin
      case 'fr':
      default:
        return '🇫🇷'; // Drapeau de la France
    }
  }
  
  /// Vérifie si la langue actuelle est le Fongbé
  bool get isFongbe => _currentLanguage == 'fon';
  
  /// Vérifie si la langue actuelle est le Français
  bool get isFrench => _currentLanguage == 'fr';
}