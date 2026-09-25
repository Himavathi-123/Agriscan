import time
import logging
import os

from utils.image_utils import decode_image_bytes, draw_annotations
from utils.response_utils import format_infer_response
from services.pest_detector import PestDetector
from services.disease_detector import DiseaseDetector

logger = logging.getLogger("inference_service")

class InferenceService:
    def __init__(
        self,
        pest_model_path: str = "./models/pest/best.pt",
        disease_model_path: str = "./models/disease/disease_model.pt",
        default_pest_conf: float = 0.40,
        default_disease_conf: float = 0.40,
        results_dir: str = "./static/results"
    ):
        self.pest_detector = PestDetector(model_path=pest_model_path)
        self.disease_detector = DiseaseDetector(model_path=disease_model_path)
        self.default_pest_conf = default_pest_conf
        self.default_disease_conf = default_disease_conf
        self.results_dir = results_dir

    def run_inference(self, image_bytes: bytes, pest_conf: float = None, disease_conf: float = None) -> dict:
        start_time = time.time()
        
        effective_pest_conf = pest_conf if pest_conf is not None else self.default_pest_conf
        effective_disease_conf = disease_conf if disease_conf is not None else self.default_disease_conf
        
        # 1. Decode image
        image_np, (width, height) = decode_image_bytes(image_bytes)
        
        # 2. Run Pest Model
        pest_detections = self.pest_detector.predict(image_np, confidence_threshold=effective_pest_conf)
        
        # 3. Run Disease Model
        disease_detections = self.disease_detector.predict(image_np, confidence_threshold=effective_disease_conf)
        
        # 4. Generate annotated image if detections exist
        annotated_url = None
        if len(pest_detections) > 0 or len(disease_detections) > 0:
            try:
                annotated_url = draw_annotations(image_np, pest_detections, disease_detections, self.results_dir)
            except Exception as e:
                logger.error(f"Failed to generate annotated image: {e}")
                annotated_url = None

        # 5. Format & return structured response
        return format_infer_response(
            pests=pest_detections,
            diseases=disease_detections,
            img_width=width,
            img_height=height,
            start_time=start_time,
            annotated_image_url=annotated_url,
            pest_ok=self.pest_detector.is_loaded,
            disease_ok=self.disease_detector.is_loaded
        )

    def get_health_status(self) -> dict:
        pest_ok = self.pest_detector.is_loaded
        disease_ok = self.disease_detector.is_loaded
        
        status = "ok" if (pest_ok and disease_ok) else ("degraded" if pest_ok else "unhealthy")
        
        return {
            "status": status,
            "models": {
                "pest": { "loaded": pest_ok },
                "disease": { "loaded": disease_ok }
            },
            "device": self.pest_detector.device
        }
