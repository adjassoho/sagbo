import 'package:flutter/material.dart';
import 'fongbe_strings.dart';

/// Service de localisation pour l'application Sagbo
/// Gère les traductions entre Français et Fongbé
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
  
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();
  
  /// Langues supportées
  static const List<Locale> supportedLocales = [
    Locale('fr', 'FR'), // Français
    Locale('fon', 'BJ'), // Fongbé (Bénin)
  ];
  
  /// Obtient une traduction selon la langue actuelle
  String translate(String key, [List<String>? params]) {
    if (locale.languageCode == 'fon') {
      return FongbeStrings.get(key, params);
    }
    
    // Traductions françaises par défaut
    return _getFrenchTranslation(key, params);
  }
  
  /// Traductions françaises (langue par défaut)
  String _getFrenchTranslation(String key, [List<String>? params]) {
    const Map<String, String> frenchTranslations = {
      // Écran de permissions
      'permissions_required': 'Permissions requises',
      'permissions_description': 'Sagbo a besoin de ces permissions pour fonctionner correctement :',
      'permissions_denied_message': 'Certaines permissions ont été définitivement refusées. Veuillez les autoriser manuellement dans les paramètres de l\'application.',
      'cancel': 'Annuler',
      'open_settings': 'Ouvrir les paramètres',
      'allow_permissions': 'Autoriser les permissions',
      
      // Permissions spécifiques
      'microphone': 'Microphone',
      'contacts': 'Contacts',
      'phone': 'Téléphone',
      'microphone_description': 'Nécessaire pour la reconnaissance vocale',
      'contacts_description': 'Nécessaire pour appeler vos contacts',
      'phone_description': 'Nécessaire pour passer des appels',
      'permission_required_general': 'Permission requise pour le fonctionnement de l\'application',
      
      // États des permissions
      'checking': 'Vérification...',
      'granted': 'Accordée',
      'denied': 'Refusée',
      'permanently_denied': 'Définitivement refusée',
      'unknown': 'Inconnue',
      
      // Écran principal
      'app_title': 'Sagbo',
      'checking_permissions': 'Vérification des permissions...',
      'api_status_checking': 'Vérification...',
      'listening_in_progress': 'Écoute en cours... ({0}s)',
      'main_greeting': 'ZIN BO ƉƆ XÓ',
      'speak_minimum': 'Parlez au moins 2 secondes',
      
      // États de l'API
      'local_mode': 'Mode local',
      'server_error': 'Erreur serveur',
      'offline': 'Hors ligne',
      'error': 'Erreur',
      'online': 'En ligne',
      
      // Messages d'erreur réseau
      'api_unavailable': '⚠️ Mode local activé\nL\'API est temporairement indisponible',
      'server_problem': '🔧 Problème serveur\nEssayez à nouveau dans quelques instants',
      'connection_problem': '📡 Problème de connexion\nVérifiez votre internet',
      
      // Commandes vocales
      'voice_not_available': 'La reconnaissance vocale n\'est pas disponible sur cet appareil',
      'microphone_permission_denied': 'Permission de microphone refusée',
      'listening_start_error': 'Erreur lors du démarrage de l\'écoute: {0}',
      'listening_stop_error': 'Erreur lors de l\'arrêt de l\'écoute: {0}',
      'command_not_recognized': 'Commande non reconnue',
      'command_not_supported': 'Type de commande non pris en charge',
      'no_contact_specified': 'Aucun nom de contact spécifié',
      'searching_contact': 'Recherche de {0}...',
      'contact_found': 'Contact trouvé: {0}',
      'calling_in_progress': 'Appel en cours...',
      'contact_not_found': 'Contact "{0}" non trouvé',
      'check_name_pronunciation': 'Vérifiez le nom ou la prononciation',
      'calling_contact': 'Appel de {0}...',
      'call_error': 'Erreur lors de l\'appel: {0}',
      'cannot_call_contact': 'Impossible d\'appeler {0}',
      'cannot_launch_call': 'Impossible de lancer l\'appel vers {0}',
      
      // Messages de permission détaillés
      'microphone_permission_message': 'Permission microphone refusée. Veuillez l\'autoriser dans les paramètres.',
      'microphone_permanently_denied': 'Permission microphone définitivement refusée. Allez dans Paramètres > Applications > Sagbo > Permissions pour l\'autoriser.',
      
      // Messages de synchronisation
      'contacts_synced_success': '✅ Contacts synchronisés avec succès',
      'contacts_sync_error': '❌ Erreur lors de la synchronisation des contacts: {0}',
    };
    
    String translation = frenchTranslations[key] ?? key;
    
    if (params != null) {
      for (int i = 0; i < params.length; i++) {
        translation = translation.replaceAll('{$i}', params[i]);
      }
    }
    
    return translation;
  }
  
  /// Raccourcis pour les traductions courantes
  String get permissionsRequired => translate('permissions_required');
  String get cancel => translate('cancel');
  String get openSettings => translate('open_settings');
  String get microphone => translate('microphone');
  String get contacts => translate('contacts');
  String get phone => translate('phone');
  String get checking => translate('checking');
  String get granted => translate('granted');
  String get denied => translate('denied');
  String get appTitle => translate('app_title');
  String get mainGreeting => translate('main_greeting');
  String get speakMinimum => translate('speak_minimum');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['fr', 'fon'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }
  
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}