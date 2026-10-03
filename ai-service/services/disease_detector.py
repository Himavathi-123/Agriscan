import os
import logging
import torch
from ultralytics import YOLO

from huggingface_hub import hf_hub_download

logger = logging.getLogger("disease_detector")

# PlantDoc Dataset Standard Taxonomy Mapping
PLANTDOC_CLASSES = {
    0: "Apple Scab Leaf",
    1: "Apple Rust Leaf",
    2: "Apple Leaf",
    3: "Bell Pepper Leaf Spot",
    4: "Bell Pepper Leaf",
    5: "Blueberry Leaf",
    6: "Cherry Leaf",
    7: "Corn Gray Leaf Spot",
    8: "Corn Common Rust Leaf",
    9: "Corn Leaf Blight",
    10: "Grape Leaf Black Rot",
    11: "Grape Leaf",
    12: "Peach Leaf",
    13: "Potato Leaf Early Blight",
    14: "Potato Leaf Late Blight",
    15: "Potato Leaf",
    16: "Raspberry Leaf",
    17: "Soybean Leaf",
    18: "Squash Powdery Mildew Leaf",
    19: "Tomato Bacterial Spot Leaf",
    20: "Tomato Early Blight Leaf",
    21: "Tomato Late Blight Leaf",
    22: "Tomato Mold Leaf",
    23: "Tomato Septoria Leaf Spot",
    24: "Tomato Two Spotted Spider Mites Leaf",
    25: "Tomato Yellow Leaf Curl Virus",
    26: "Tomato Mosaic Virus Leaf",
    27: "Tomato Leaf"
}

class DiseaseDetector:
    def __init__(
        self,
        model_path: str = "./models/disease/PlantDiseaseDetection.pt",
        repo_id: str = "JK-TK/PlantDiseaseDetection",
        filename: str = "PlantDiseaseDetection.pt"
    ):
        self.model_path = model_path
        self.repo_id = repo_id
        self.filename = filename
        self.model = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.is_loaded = False
        
        self.load_model()

    def load_model(self):
        try:
            # Fallback path check
            if not os.path.exists(self.model_path) and os.path.exists("./models/disease/disease_model.pt"):
                self.model_path = "./models/disease/disease_model.pt"

            if not os.path.exists(self.model_path):
                logger.info(f"Plant disease model checkpoint not found at '{self.model_path}'. Downloading from Hugging Face ({self.repo_id})...")
                os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
                downloaded_path = hf_hub_download(
                    repo_id=self.repo_id,
                    filename=self.filename,
                    local_dir=os.path.dirname(self.model_path)
                )
                self.model_path = downloaded_path
                logger.info(f"Plant disease model downloaded successfully to {self.model_path}.")

            logger.info(f"Loading PlantDoc disease detection model from {self.model_path} on device: {self.device}...")
            self.model = YOLO(self.model_path)
            self.model.to(self.device)
            self.is_loaded = True
            import gc
            gc.collect()
            logger.info("PlantDoc disease detection model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load disease detection model from {self.model_path}: {e}", exc_info=True)
            self.is_loaded = False

    def predict(self, image_np, confidence_threshold: float = 0.40) -> list:
        if not self.is_loaded or self.model is None:
            return []

        try:
            with torch.inference_mode():
                results = self.model(image_np, conf=confidence_threshold, verbose=False)
            detections = []
            
            for result in results:
                boxes = result.boxes
                if boxes is None:
                    continue
                
                for box in boxes:
                    cls_id = int(box.cls[0].item())
                    # Resolve class name from model metadata, or fallback to PlantDoc class map
                    cls_name = result.names.get(cls_id) if (result.names and cls_id in result.names) else PLANTDOC_CLASSES.get(cls_id, f"disease_{cls_id}")
                    conf = float(box.conf[0].item())
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
            logger.error(f"Error during disease detection inference: {e}", exc_info=True)
            return []
