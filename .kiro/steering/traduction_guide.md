# Guide d'utilisation du système de traduction Sagbo

Ce document explique comment utiliser et étendre le système de traduction multilingue implémenté dans l'application Sagbo.

## Structure du système de traduction

Le système de traduction est composé de plusieurs fichiers clés :

1. **`lib/config/app_localizations.dart`** - Classe principale de gestion des traductions
2. **`lib/config/fongbe_strings.dart`** - Traductions en langue Fongbé
3. **`lib/config/language_manager.dart`** - Gestionnaire de changement de langue

## Langues supportées

Actuellement, l'application supporte deux langues :
- **Français** (fr) - Langue par défaut
- **Fongbé** (fon) - Langue locale du Bénin

## Comment utiliser les traductions

### Dans les widgets Flutter

Pour utiliser une traduction dans un widget Flutter :

```dart
// Obtenir l'instance de AppLocalizations
final localizations = AppLocalizations.of(context);

// Utiliser une traduction simple
Text(localizations?.translate('permissions_required') ?? 'Permissions requises')

// Utiliser une traduction avec paramètres
Text(localizations?.translate('searching_contact', [contactName]) ?? 'Recherche de $contactName...')
```

### Dans les services

Pour les services qui n'ont pas accès au contexte, vous pouvez :

1. Passer le contexte au service lors de l'initialisation
2. Utiliser la classe `LocalizedVoiceProcessor` qui encapsule le `VoiceCommandProcessor`

```dart
// Dans un widget
_voiceCommandProcessor.setContext(context);

// Dans le service
String message = _t('command_not_recognized');
```

## Ajouter de nouvelles traductions

Pour ajouter de nouvelles chaînes de caractères à traduire :

1. Ajoutez la clé et la valeur en français dans `AppLocalizations._getFrenchTranslation()`
2. Ajoutez la clé et la valeur en fongbé dans `FongbeStrings.translations`

Exemple :

```dart
// Dans AppLocalizations
'new_key': 'Nouvelle chaîne en français',

// Dans FongbeStrings
'new_key': 'Chaîne traduite en fongbé',
```

## Ajouter une nouvelle langue

Pour ajouter une nouvelle langue :

1. Créez un nouveau fichier `lib/config/new_language_strings.dart`
2. Ajoutez la langue dans `AppLocalizations.supportedLocales`
3. Modifiez la méthode `translate()` pour prendre en compte la nouvelle langue

## Bonnes pratiques

1. Utilisez toujours des clés descriptives pour les traductions
2. Regroupez les traductions par catégorie dans les commentaires
3. Utilisez des paramètres pour les valeurs dynamiques
4. Testez toutes les langues après avoir ajouté de nouvelles traductions

## Changement de langue

L'application permet de changer de langue à l'aide du bouton dans la barre d'application. La préférence de langue est sauvegardée entre les sessions.