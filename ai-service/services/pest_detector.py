import os
import logging
import torch
from ultralytics import YOLO
from huggingface_hub import hf_hub_download

logger = logging.getLogger("pest_detector")

class PestDetector:
    def __init__(self, model_path: str = "./models/pest/best.pt", repo_id: str = "underdogquality/yolo11s-pest-detection", filename: str = "best.pt"):
        self.model_path = model_path
        self.repo_id = repo_id
        self.filename = filename
        self.model = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.is_loaded = False
        
        self.load_model()

    def load_model(self):
        try:
            # Ensure model file exists locally; if not, download from Hugging Face
            if not os.path.exists(self.model_path):
                logger.info(f"Pest model weights not found at {self.model_path}. Downloading from Hugging Face ({self.repo_id})...")
                os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
                downloaded_path = hf_hub_download(
                    repo_id=self.repo_id,
                    filename=self.filename,
                    local_dir=os.path.dirname(self.model_path)
                )
                self.model_path = downloaded_path
                logger.info(f"Pest model downloaded successfully to {self.model_path}.")

            logger.info(f"Loading YOLO pest detection model from {self.model_path} on device: {self.device}...")
            self.model = YOLO(self.model_path)
            self.model.to(self.device)
            self.is_loaded = True
            logger.info("Pest detection model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load pest detection model: {e}", exc_info=True)
            self.is_loaded = False

    def predict(self, image_np, confidence_threshold: float = 0.40) -> list:
        if not self.is_loaded or self.model is None:
            logger.warning("Pest model is not loaded. Returning empty detections.")
            return []

        try:
            results = self.model(image_np, conf=confidence_threshold, verbose=False)
            detections = []
            
            for result in results:
                boxes = result.boxes
                if boxes is None:
                    continue
                
                for box in boxes:
                    cls_id = int(box.cls[0].item())
                    cls_name = result.names.get(cls_id, f"pest_{cls_id}")
                    conf = float(box.conf[0].item())
                    
                    # Bounding box coordinates (x1, y1, x2, y2)
                    xyxy = box.xyxy[0].tolist()
                    
                    detections.append({
                        "classId": cls_id,
                        "name": str(cls_name).replace("_", " "),
                        "confidence": round(conf, 4),
                        "bbox": {
                            "x1": round(xyxy[0], 2),
                            "y1": round(xyxy[1], 2),
                            "x2": round(xyxy[2], 2),
                            "y2": round(xyxy[3], 2)
                        }
                    })
                    
            return detections
        except Exception as e:
            logger.error(f"Error during pest detection inference: {e}", exc_info=True)
            return []
