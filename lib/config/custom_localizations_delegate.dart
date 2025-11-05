import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Delegate personnalisé pour MaterialLocalizations en Fongbé
class FongbeMaterialLocalizations extends DefaultMaterialLocalizations {
  const FongbeMaterialLocalizations();

  static const LocalizationsDelegate<MaterialLocalizations> delegate = 
      _FongbeMaterialLocalizationsDelegate();
}

class _FongbeMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _FongbeMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'fon';

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return SynchronousFuture<MaterialLocalizations>(const FongbeMaterialLocalizations());
  }

  @override
  bool shouldReload(_FongbeMaterialLocalizationsDelegate old) => false;
}

/// Delegate personnalisé pour CupertinoLocalizations en Fongbé
class FongbeCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const FongbeCupertinoLocalizations();

  static const LocalizationsDelegate<CupertinoLocalizations> delegate = 
      _FongbeCupertinoLocalizationsDelegate();
}

class _FongbeCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FongbeCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'fon';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return SynchronousFuture<CupertinoLocalizations>(const FongbeCupertinoLocalizations());
  }

  @override
  bool shouldReload(_FongbeCupertinoLocalizationsDelegate old) => false;
}

/// Classe personnalisée pour fournir les traductions en français 
/// quand la locale Fongbé n'est pas supportée nativement
class FallbackLocalizationDelegate extends LocalizationsDelegate<dynamic> {
  const FallbackLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<dynamic> load(Locale locale) async => null;

  @override
  bool shouldReload(FallbackLocalizationDelegate old) => false;
}
