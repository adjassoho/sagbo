# sagbo

A new Flutter project.

## Getting Started

# Sagbo - Assistant Vocal en Langue Fongbé

Sagbo est une application mobile d'assistant vocal qui permet aux utilisateurs de passer des appels téléphoniques en utilisant des commandes vocales en langue Fongbé.

## Fonctionnalités principales

- **Reconnaissance vocale en Fongbé** : Transcription automatique de la parole en texte
- **Commandes vocales** : Dites "ylɔ" + nom du contact pour appeler quelqu'un
- **Répertoire intelligent** : Sauvegarde locale des contacts pour un accès rapide
- **Support multilingue** : Traduction automatique des noms Fongbé vers Français

## Architecture

### Application Flutter (Frontend)
- Interface utilisateur intuitive
- Enregistrement audio optimisé (WAV 16kHz mono)
- Gestion des permissions (microphone, contacts, téléphone)
- Synchronisation automatique des contacts

### API Python (Backend)
- Modèle ASR SpeechBrain pour la reconnaissance vocale Fongbé
- API REST FastAPI pour le traitement des requêtes
- Support CORS pour les requêtes cross-origin

## Installation

### Prérequis
- Flutter SDK 3.0+
- Python 3.8+
- Android Studio / Xcode (pour le développement mobile)

### Installation de l'API

1. Naviguer vers le dossier de l'API :
```bash
cd tous_infos_api
```

2. Installer les dépendances :
```bash
pip install -r requirements.txt
```

3. Démarrer l'API :
```bash
python start_api.py
```

L'API sera accessible sur `http://localhost:8000`

### Installation de l'application Flutter

1. Installer les dépendances Flutter :
```bash
flutter pub get
```

2. Configurer l'URL de l'API dans `lib/services/speech_recognition_service.dart` si nécessaire

3. Lancer l'application :
```bash
flutter run
```

## Utilisation

1. **Première utilisation** : Accepter les permissions demandées (microphone, contacts, téléphone)

2. **Synchronisation des contacts** : L'application synchronise automatiquement vos contacts au démarrage

3. **Passer un appel** :
   - Appuyer sur le bouton microphone
   - Dire clairement "ylɔ" suivi du nom du contact (ex: "ylɔ koku")
   - Parler pendant au moins 2 secondes
   - L'application reconnaîtra la commande et lancera l'appel

## Commandes vocales supportées

| Commande | Description | Exemple |
|----------|-------------|---------|
| ylɔ + nom | Appeler un contact | "ylɔ mama" (appeler maman) |

## Résolution des problèmes

### L'API ne répond pas
- Vérifier que l'API Python est bien démarrée
- Vérifier la connexion internet
- Désactiver temporairement AdGuard DNS si activé

### Erreur "Audio file too small"
- Parler plus fort et plus longtemps (minimum 2 secondes)
- Rapprocher le téléphone de votre bouche

### Contact non trouvé
- Vérifier que le contact existe dans votre répertoire
- Essayer différentes prononciations du nom
- Synchroniser manuellement les contacts

## Structure du projet

```
new_sagbo/
├── lib/                    # Code source Flutter
│   ├── services/          # Services (API, contacts, etc.)
│   ├── screens/           # Écrans de l'application
│   └── config/            # Configuration
├── tous_infos_api/        # API Python
│   ├── main.py           # Point d'entrée de l'API
│   └── start_api.py      # Script de démarrage
├── assets/                # Images et ressources
└── pubspec.yaml          # Dépendances Flutter
```

## Développement

### Ajouter de nouvelles commandes

1. Modifier `lib/services/fongbe_translation_service.dart` pour ajouter les traductions
2. Mettre à jour `parseVoiceCommand()` pour reconnaître la nouvelle commande
3. Ajouter le traitement dans `voice_command_processor.dart`

### Améliorer la reconnaissance

- Le modèle ASR peut être affiné avec plus de données Fongbé
- Ajuster les paramètres audio dans `ApiConfig` si nécessaire

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## Contributeurs

- Développé pour la communauté Fongbé
- Utilise le modèle ASR SpeechBrain pour Fongbé

## Support

Pour toute question ou problème, veuillez ouvrir une issue sur le dépôt GitHub.
