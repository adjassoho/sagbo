#!/usr/bin/env python3
"""
Script de démarrage pour l'API Sagbo Fongbe ASR
"""

import os
import sys
import subprocess
import logging
from pathlib import Path

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def check_requirements():
    """Vérifie que toutes les dépendances sont installées"""
    required_packages = [
        'fastapi',
        'uvicorn',
        'speechbrain',
        'torchaudio',
        'torch'
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package)
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        logger.error(f"Packages manquants: {', '.join(missing_packages)}")
        logger.info("Installation des packages manquants...")
        
        # Installer les packages manquants
        for package in missing_packages:
            try:
                subprocess.check_call([sys.executable, '-m', 'pip', 'install', package])
                logger.info(f"✓ {package} installé")
            except subprocess.CalledProcessError:
                logger.error(f"✗ Échec de l'installation de {package}")
                return False
    
    return True

def create_directories():
    """Crée les répertoires nécessaires"""
    directories = [
        'temp_audio_files',
        'pretrained_models',
        'logs'
    ]
    
    for directory in directories:
        Path(directory).mkdir(exist_ok=True)
        logger.info(f"✓ Répertoire '{directory}' créé/vérifié")

def test_model_loading():
    """Teste le chargement du modèle ASR"""
    try:
        from speechbrain.inference.ASR import EncoderASR
        logger.info("Test de chargement du modèle ASR...")
        
        # Essayer de charger le modèle
        model_source = "speechbrain/asr-wav2vec2-dvoice-fongbe"
        saved_model_dir = "pretrained_models/asr-wav2vec2-dvoice-fongbe"
        
        # Ceci peut prendre du temps la première fois
        logger.info("Chargement du modèle (cela peut prendre quelques minutes la première fois)...")
        asr_model = EncoderASR.from_hparams(
            source=model_source,
            savedir=saved_model_dir
        )
        logger.info("✓ Modèle ASR chargé avec succès!")
        return True
        
    except Exception as e:
        logger.error(f"✗ Erreur lors du chargement du modèle: {e}")
        return False

def start_api():
    """Démarre l'API FastAPI"""
    logger.info("Démarrage de l'API Sagbo Fongbe ASR...")
    
    # Paramètres de démarrage
    host = os.getenv('API_HOST', '0.0.0.0')
    port = int(os.getenv('API_PORT', '8000'))
    reload = os.getenv('API_RELOAD', 'true').lower() == 'true'
    
    logger.info(f"Configuration:")
    logger.info(f"  - Host: {host}")
    logger.info(f"  - Port: {port}")
    logger.info(f"  - Reload: {reload}")
    logger.info(f"  - URL: http://{host}:{port}")
    
    # Lancer uvicorn
    cmd = [
        sys.executable, '-m', 'uvicorn',
        'main:app',
        '--host', host,
        '--port', str(port),
    ]
    
    if reload:
        cmd.append('--reload')
    
    try:
        subprocess.run(cmd)
    except KeyboardInterrupt:
        logger.info("API arrêtée par l'utilisateur")
    except Exception as e:
        logger.error(f"Erreur lors du démarrage de l'API: {e}")
        sys.exit(1)

def main():
    """Fonction principale"""
    logger.info("=== Démarrage de l'API Sagbo Fongbe ASR ===")
    
    # Vérifier les dépendances
    if not check_requirements():
        logger.error("Échec de la vérification des dépendances")
        sys.exit(1)
    
    # Créer les répertoires nécessaires
    create_directories()
    
    # Tester le chargement du modèle
    if not test_model_loading():
        logger.warning("Le modèle n'a pas pu être chargé maintenant, il sera chargé au démarrage de l'API")
    
    # Démarrer l'API
    start_api()

if __name__ == "__main__":
    main()
