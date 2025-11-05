import fastapi
import uvicorn
import shutil
import os
import logging
from fastapi import UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from speechbrain.inference.ASR import EncoderASR


import torchaudio
torchaudio.set_audio_backend("soundfile")



# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = fastapi.FastAPI(title="API Fongbe ASR", version="1.0.0")

# Configurer CORS pour accepter les requêtes depuis n'importe quelle origine
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Permettre toutes les origines
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load the ASR model on startup
# This might take a few minutes the first time as it downloads the model
model_source = "speechbrain/asr-wav2vec2-dvoice-fongbe"
saved_model_dir = "pretrained_models/asr-wav2vec2-dvoice-fongbe"

# Ensure the saved_model_dir exists
os.makedirs(saved_model_dir, exist_ok=True)

asr_model = None

@app.on_event("startup")
async def load_model():
    global asr_model
    try:
        # For CPU inference (default)
        asr_model = EncoderASR.from_hparams(
            source=model_source, 
            savedir=saved_model_dir
        )
        print(f"Model {model_source} loaded successfully.")
        # To perform inference on GPU, use:
        # asr_model = EncoderASR.from_hparams(
        #     source=model_source, 
        #     savedir=saved_model_dir, 
        #     run_opts={"device":"cuda"}
        # )
        # print(f"Model {model_source} loaded successfully on CUDA.")
    except Exception as e:
        print(f"Error loading model: {e}")
        # You might want to raise an exception here or handle it gracefully
        # For now, we'll let the app start, but transcription will fail.
        asr_model = None

@app.post("/transcribe/")
async def transcribe_audio(file: UploadFile = File(...) ):
    if not asr_model:
        raise HTTPException(status_code=503, detail="ASR model is not available. Check server logs.")

    if not file:
        raise HTTPException(status_code=400, detail="No file provided.")

    # Define a temporary path to save the uploaded file
    # It's good practice to save to a temporary directory and ensure unique filenames
    temp_dir = "temp_audio_files"
    os.makedirs(temp_dir, exist_ok=True)
    
    # Générer un nom de fichier unique pour éviter les conflits
    import uuid
    file_extension = os.path.splitext(file.filename)[1] if file.filename else ".wav"
    unique_filename = f"audio_{uuid.uuid4().hex}{file_extension}"
    temp_file_path = os.path.join(temp_dir, unique_filename)

    try:
        # Save the uploaded file temporarily
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # Vérifier que le fichier a été créé et n'est pas vide
        if not os.path.exists(temp_file_path):
            raise HTTPException(status_code=500, detail="Failed to save audio file")
        
        file_size = os.path.getsize(temp_file_path)
        logger.info(f"File saved: {temp_file_path}, size: {file_size} bytes")
        
        if file_size == 0:
            raise HTTPException(status_code=400, detail="Audio file is empty")
        elif file_size < 1000:  # Moins de 1KB
            raise HTTPException(status_code=400, detail="Audio file is too small")

        # Perform transcription
        logger.info(f"Transcribing file: {temp_file_path}")
        
        try:
            # The transcribe_file method handles resampling and mono channel selection if needed
            transcription = asr_model.transcribe_file(temp_file_path)
            logger.info(f"Transcription result: {transcription}")
            
            # Nettoyer le résultat de transcription
            if isinstance(transcription, list) and len(transcription) > 0:
                transcription_text = transcription[0] if transcription[0] else ""
            else:
                transcription_text = str(transcription) if transcription else ""
            
            # Réponse structurée
            response = {
                "filename": file.filename,
                "transcription": transcription_text,
                "text": transcription_text,  # Alias pour compatibilité
                "file_size": file_size,
                "status": "success"
            }
            
            return response
            
        except Exception as transcribe_error:
            logger.error(f"Transcription error: {transcribe_error}")
            raise HTTPException(
                status_code=500, 
                detail=f"Transcription failed: {str(transcribe_error)}"
            )

    except Exception as e:
        # Log the exception for debugging
        print(f"Error during transcription: {e}")
        raise HTTPException(status_code=500, detail=f"Could not transcribe the audio file: {str(e)}")
    finally:
        # Clean up: remove the temporary file
        if os.path.exists(temp_file_path):
            os.remove(temp_file_path)
        # Optionally, remove the temp_dir if it's empty and you created it for this request only
        # For simplicity, we leave it for now but in a production system, consider more robust temp file management.

@app.get("/")
async def root():
    return {"message": "Fongbe ASR API is running. Use the /transcribe/ endpoint to transcribe audio."}

# To run the app (e.g., from the terminal):
# uvicorn main:app --reload --host 0.0.0.0 --port 8000

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000) 