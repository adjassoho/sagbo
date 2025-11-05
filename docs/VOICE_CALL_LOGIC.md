# Logique d'appel vocal en Fongbè

## Vue d'ensemble

L'assistant vocal Sagbo peut lancer des appels téléphoniques en reconnaissant des commandes vocales en langue fongbè. La logique est flexible et accepte plusieurs variations de prononciation.

## Format de commande

La commande d'appel suit ce format :
```
[préfixe]lɔ [nom du contact]
```

### Variations acceptées

L'API de transcription vocale peut interpréter la commande de différentes manières :
- `yolo jean` (transcription phonétique)
- `ylɔ paul` (transcription avec caractères fongbè)
- `ɔlɔ marie` (sans consonne initiale)
- `yɔlɔ pierre` (avec voyelle intermédiaire)
- `alɔ antoine` (avec voyelle initiale différente)
- `elo luc` (transcription simplifiée)

### Logique de détection

Le système utilise une expression régulière flexible qui :
1. Détecte "lɔ" ou "lo" dans la commande
2. Peut être précédé de n'importe quelle lettre (y, ɔ, a, e, etc.)
3. Extrait le nom qui suit

### Exemples de commandes valides

| Commande vocale | Nom extrait | Action |
|-----------------|-------------|---------|
| `yolo jean` | jean | Appeler Jean |
| `ylɔ kɔku` | Koku | Appeler Koku (traduit du fongbè) |
| `ɔlɔ marie` | marie | Appeler Marie |
| `yololuc` | luc | Appeler Luc (sans espace) |

## Flux d'exécution

1. **Réception de la transcription** : L'API de reconnaissance vocale envoie la transcription
2. **Analyse de la commande** : `FongbeTranslationService.parseVoiceCommand()` détecte le pattern
3. **Extraction du nom** : Le nom après "lɔ/lo" est extrait
4. **Traduction** : Si le nom est en fongbè, il est traduit en français
5. **Recherche du contact** : 
   - D'abord dans la sauvegarde locale (rapide)
   - Ensuite dans les contacts du téléphone
6. **Lancement de l'appel** : Via `url_launcher` avec le schéma `tel:`

## Traduction des noms

Le service traduit automatiquement les noms fongbè courants :
- `kɔku` → Koku (lundi)
- `kɔfí` → Kofi
- `ajídi` → Adjidji (mardi)
- etc.

## Gestion des erreurs

Le système gère plusieurs cas d'erreur :
- Contact non trouvé
- Pas de numéro de téléphone
- Permissions manquantes
- Commande non reconnue

## Debug

Les logs de debug affichent :
- La commande détectée
- Le nom extrait
- La traduction appliquée
- Les erreurs éventuelles

## Amélioration de la reconnaissance

Pour améliorer la reconnaissance des noms :
1. Le système utilise une recherche approximative
2. Normalise les noms (suppression des accents)
3. Calcule un score de similarité
4. Accepte les correspondances partielles au-dessus d'un seuil (70%)
