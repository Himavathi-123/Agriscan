import os
import gc
import logging
from typing import Optional
from dotenv import load_dotenv

# Optimize PyTorch RAM footprint for low-memory cloud hosts (512MB limit)
os.environ["OMP_NUM_THREADS"] = "1"
os.environ["MKL_NUM_THREADS"] = "1"
import torch
torch.set_num_threads(1)
torch.set_grad_enabled(False)

# Load environment variables
load_dotenv()

from fastapi import FastAPI, UploadFile, File, Form, HTTPException, status
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from services.inference_service import InferenceService

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("ai_service")

# Environment Configurations
AI_PORT = int(os.getenv("AI_PORT", "8000"))
PEST_MODEL_PATH = os.getenv("PEST_MODEL_PATH", "./models/pest/best.pt")
DISEASE_MODEL_PATH = os.getenv("DISEASE_MODEL_PATH", "./models/disease/disease_model.pt")
PEST_CONFIDENCE = float(os.getenv("PEST_CONFIDENCE", "0.40"))
DISEASE_CONFIDENCE = float(os.getenv("DISEASE_CONFIDENCE", "0.40"))
RESULTS_DIR = os.getenv("RESULTS_DIR", "./static/results")

# Ensure static results directory exists
os.makedirs(RESULTS_DIR, exist_ok=True)

# Initialize FastAPI App
app = FastAPI(
    title="AgriScan AI Inference Service",
    description="Microservice hosting YOLO11s IP102 Pest Detection and PlantDoc Disease Models",
    version="1.0.0"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Static Results Directory for annotated images
app.mount("/results", StaticFiles(directory=RESULTS_DIR), name="results")

# Initialize Inference Service (Loads Models Once on Startup)
inference_service = InferenceService(
    pest_model_path=PEST_MODEL_PATH,
    disease_model_path=DISEASE_MODEL_PATH,
    default_pest_conf=PEST_CONFIDENCE,
    default_disease_conf=DISEASE_CONFIDENCE,
    results_dir=RESULTS_DIR
)

@app.get("/health")
def health_check():
    """
    Returns AI Microservice Health & Model Loading Status.
    """
    return inference_service.get_health_status()

@app.post("/infer")
async def infer(
    image: UploadFile = File(...),
    pest_confidence: Optional[float] = Form(None),
    disease_confidence: Optional[float] = Form(None)
):
    """
    Performs Pest and Disease AI Model Inference on the uploaded crop image.
    """
    if not image or not image.filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No image file provided."
        )

    # Basic MIME validation
    content_type = image.content_type or ""
    if content_type and not content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file format: {content_type}. Only images are supported."
        )

    try:
        image_bytes = await image.read()
        if len(image_bytes) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Empty image file received."
            )

        logger.info(f"Processing inference request for image: {image.filename} ({len(image_bytes)} bytes)")
        
        result = inference_service.run_inference(
            image_bytes=image_bytes,
            pest_conf=pest_confidence,
            disease_conf=disease_confidence
        )
        
        logger.info(f"Inference completed in {result['processingTimeMs']}ms. Pests: {result['summary']['pestCount']}, Diseases: {result['summary']['diseaseCount']}")
        return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Inference pipeline execution error: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Inference execution failure: {str(e)}"
        )

if __name__ == "__main__":
    logger.info(f"Starting AgriScan AI Inference Microservice on port {AI_PORT}...")
    uvicorn.run("app:app", host="0.0.0.0", port=AI_PORT, reload=False)
