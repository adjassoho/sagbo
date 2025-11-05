# Fiche d'Utilisation : API de Transcription Audio Fongbe

Ce document décrit comment utiliser l'API de transcription audio pour la langue Fongbe.

## Endpoint de Transcription

-   **URL :** `https://fongbe.work.gd/api/transcribe/` .
-   **Méthode HTTP :** `POST`
-   **Type de requête :** `multipart/form-data`

## Paramètres de la Requête

La requête doit contenir une partie de formulaire nommée `file` avec le fichier audio à transcrire.

-   **Clé :** `file`
-   **Valeur :** Le fichier audio (ex: `.wav`, `.mp3`). Il est recommandé d'utiliser des fichiers `.wav` avec un encodage PCM 16 bits pour une compatibilité maximale, car c'est le format pour lequel le modèle est généralement optimisé et pour lequel `torchaudio` a un bon support avec `libsndfile`.

## Réponse en Cas de Succès

Si la transcription réussit, l'API retourne un code de statut `200 OK` et un corps de réponse JSON avec la structure suivante :

```json
{
  "filename": "nom_de_votre_fichier.wav",
  "transcription": "le texte transcrit en fongbe ici"
}
```

-   `filename`: Le nom du fichier original envoyé.
-   `transcription`: Le texte résultant de la transcription audio.

## Réponses d'Erreur Courantes

-   **Code `400 Bad Request`:**
    -   Message : `{"detail":"No file provided."}`
    -   Cause : Aucun fichier n'a été inclus dans la requête avec la clé `file`.
-   **Code `404 Not Found`:**
    -   Cause (si Nginx est utilisé) : L'URL demandée n'est pas correctement mappée par Nginx vers l'application FastAPI, ou l'URL elle-même est incorrecte.
    -   Cause (si FastAPI est directement exposé) : L'endpoint demandé n'existe pas (vérifiez le chemin de l'URL).
-   **Code `500 Internal Server Error`:**
    -   Message : `{"detail":"Could not transcribe the audio file: ...raison de l'erreur..."}`
    -   Cause : Une erreur s'est produite pendant le processus de transcription. Cela peut inclure des problèmes avec le format du fichier audio (ex: `Couldn't find appropriate backend to handle uri...`), des erreurs du modèle, ou d'autres problèmes internes.
    -   Message : `{"detail":"ASR model is not available. Check server logs."}`
    -   Cause : Le modèle de reconnaissance vocale n'a pas pu être chargé correctement au démarrage de l'application. Consultez les logs du serveur Uvicorn pour plus de détails.
-   **Code `503 Service Unavailable`:**
    -   Message : `{"detail":"ASR model is not available. Check server logs."}` (peut aussi apparaître comme 503 si le modèle n'est pas chargé au moment de la requête)
    -   Cause : Le modèle ASR n'est pas disponible.

## Exemple d'Utilisation avec `curl`


```bash
curl -X POST -F "file=@/chemin/vers/votre/audio.wav" VOTRE_URL_API
```

**Exemple concret ( `https://fongbe.work.gd/api/transcribe/`) :**

```bash
curl -X POST -F "file=@./mon_fichier_fongbe.wav" https://fongbe.work.gd/api/transcribe/
```

## Test avec l'Interface Web (`index.html`)

Si vous avez le fichier `index.html` (fourni précédemment) accessible via un navigateur :

1.  Ouvrez `index.html` dans votre navigateur.
2.  Entrez l'URL complète de votre API dans le champ "URL de l'API" (ex: `https://fongbe.work.gd/api/transcribe/`).
3.  Cliquez sur "Sélectionnez un fichier" pour choisir votre fichier audio.
4.  Cliquez sur "Transcrire".
5.  Le résultat (ou une erreur) s'affichera sur la page.

    *Rappel sur CORS :* Si `index.html` est servi depuis une origine différente de l'API (ex: `file:///` localement vs. `https://fongbe.work.gd`), des problèmes CORS peuvent survenir si l'API n'est pas configurée pour les autoriser. La version actuelle de `main.py` avec `CORSMiddleware` (autorisant `"*"`) devrait gérer cela pour le développement.

## Notes Importantes

-   **Qualité Audio :** La qualité de la transcription dépendra fortement de la qualité du fichier audio (bruit de fond, clarté de la parole, etc.) et des capacités du modèle ASR sous-jacent.
-   **Taille des Fichiers / Durée :** Pour des fichiers audio très volumineux ou de longue durée, la transcription peut prendre un certain temps et consommer des ressources serveur significatives. Nginx et Uvicorn ont des timeouts par défaut qui pourraient avoir besoin d'être ajustés pour des transcriptions très longues.
-   **Formats Audio :** Bien que l'API puisse accepter divers formats (grâce à `torchaudio`), les fichiers `.wav` non compressés (PCM 16kHz, mono) sont généralement les plus fiables pour les modèles SpeechBrain.

Cette fiche devrait vous aider, vous ou d'autres utilisateurs, à interagir correctement avec votre API. 