/// Traductions des chaînes de caractères en Fongbé
/// 
/// Ce fichier contient toutes les traductions de l'interface utilisateur
/// de l'application Sagbo en langue Fongbé (parlée au Bénin)
class FongbeStrings {
  // Traductions principales
  static const Map<String, String> translations = {
    // Écran de permissions
    'permissions_required': 'Mɛ ɖo bɔ ɖokpo ɔ lɛ',
    'permissions_description': 'Sagbo hwɛ mɛ ɖo bɔ ɖokpo ɔ lɛ bo na wa ɖo azɔn:',
    'permissions_denied_message': 'Mɛ ɖo bɔ ɖokpo ɔ ɖe wo gbe. Mì na wa ɖe mɔ na ye ɖo paramètre mɛ.',
    'cancel': 'Gbɛ',
    'open_settings': 'Wla paramètre lɛ',
    'allow_permissions': 'Ɖe mɔ na mɛ ɖo bɔ ɖokpo ɔ lɛ',
    
    // Permissions spécifiques
    'microphone': 'Gbe xlɛ nu',
    'contacts': 'Mɛ lɛ',
    'phone': 'Telefɔn',
    'microphone_description': 'E hwɛ gbe se kpo',
    'contacts_description': 'E hwɛ mì mɛ lɛ ylɔ kpo',
    'phone_description': 'E hwɛ telefɔn ylɔ kpo',
    'permission_required_general': 'Mɛ ɖo bɔ ɖokpo ɔ hwɛ aplikasiɔn ɔ azɔn na',
    
    // États des permissions
    'checking': 'E ɖo kpɔn...',
    'granted': 'E na',
    'denied': 'E gbe',
    'permanently_denied': 'E gbe ɖo gbɛtɔ',
    'unknown': 'Ma nyɔn o',
    
    // Écran principal
    'app_title': 'Sagbo',
    'checking_permissions': 'E ɖo kpɔn mɛ ɖo bɔ ɖokpo ɔ lɛ...',
    'api_status_checking': 'E ɖo kpɔn...',
    'listening_in_progress': 'E ɖo se xlɛ... ({0}s)',
    'main_greeting': 'ZIN BO ƉƆ XÓ',
    'speak_minimum': 'Fo nu awe atɔ̃n ɖe kpo',
    
    // États de l'API
    'local_mode': 'Afimɛ ɖoɖo',
    'server_error': 'Sɛva nukun',
    'offline': 'Internet ma ɖo o',
    'error': 'Nukun ɖe',
    'online': 'Internet ɖo',
    
    // Messages d'erreur réseau
    'api_unavailable': '⚠️ Afimɛ ɖoɖo wazɔn\nAPI ma ɖo azɔn o fifia',
    'server_problem': '🔧 Sɛva nukun ɖe\nGbugbo ɖo azɔn ɖo azan ɖe mɛ',
    'connection_problem': '📡 Internet nukun ɖe\nKpɔn mì internet ɖe',
    
    // Commandes vocales
    'voice_not_available': 'Gbe se ma ɖo azɔn ɖo mɔsin ɔ ji o',
    'microphone_permission_denied': 'Gbe xlɛ nu mɔ gbe',
    'listening_start_error': 'Nukun ɖe ɖo gbe se ɖiɖi mɛ: {0}',
    'listening_stop_error': 'Nukun ɖe ɖo gbe se gbɛ mɛ: {0}',
    'command_not_recognized': 'Nu ɖe ma se o',
    'command_not_supported': 'Nu ɖe azɔn ma ɖo o',
    'no_contact_specified': 'Mɛ nyikɔ ma ɖo o',
    'searching_contact': 'E ɖo di {0} kpo...',
    'contact_found': 'Mɛ ɖe ɖo kpo: {0}',
    'calling_in_progress': 'E ɖo ylɔ...',
    'contact_not_found': 'Mɛ "{0}" ma ɖo kpo o',
    'check_name_pronunciation': 'Kpɔn nyikɔ ɖe alo alɔ ɖe',
    'calling_contact': 'E ɖo ylɔ {0}...',
    'call_error': 'Nukun ɖe ɖo ylɔ mɛ: {0}',
    'cannot_call_contact': 'Ma ɖo bɔ ylɔ {0} o',
    'cannot_launch_call': 'Ma ɖo bɔ ylɔ {0} o',
    
    // Messages de permission détaillés
    'microphone_permission_message': 'Gbe xlɛ nu mɔ gbe. Mì na ɖe mɔ na ye ɖo paramètre mɛ.',
    'microphone_permanently_denied': 'Gbe xlɛ nu mɔ gbe ɖo gbɛtɔ. Yi Paramètre > Aplikasiɔn > Sagbo > Mɛ ɖo bɔ ɖokpo ɔ bo na ɖe mɔ na ye.',
    
    // Messages de synchronisation
    'contacts_synced_success': '✅ Mɛ lɛ bɔ ɖo ɖeka nyuie',
    'contacts_sync_error': '❌ Nukun ɖe ɖo mɛ lɛ bɔ ɖo ɖeka mɛ: {0}',
  };
  
  /// Obtient une traduction avec support des paramètres
  static String get(String key, [List<String>? params]) {
    String translation = translations[key] ?? key;
    
    if (params != null) {
      for (int i = 0; i < params.length; i++) {
        translation = translation.replaceAll('{$i}', params[i]);
      }
    }
    
    return translation;
  }
  
  /// Vérifie si une clé de traduction existe
  static bool hasTranslation(String key) {
    return translations.containsKey(key);
  }
  
  /// Obtient toutes les clés de traduction
  static List<String> getAllKeys() {
    return translations.keys.toList();
  }
}