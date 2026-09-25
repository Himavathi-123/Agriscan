import os
import uuid
import cv2
import numpy as np
from PIL import Image
import io

def decode_image_bytes(image_bytes: bytes):
    """
    Decodes raw image bytes into a numpy ndarray (BGR format for OpenCV)
    and returns (image_np, (width, height)).
    """
    pil_img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    width, height = pil_img.size
    
    # Convert PIL Image (RGB) to OpenCV format (BGR)
    open_cv_image = np.array(pil_img)
    open_cv_image = open_cv_image[:, :, ::-1].copy()
    
    return open_cv_image, (width, height)

def draw_annotations(image: np.ndarray, pest_detections: list, disease_detections: list, output_dir: str) -> str:
    """
    Draws bounding boxes, labels, and confidence percentages on the image
    and saves it to output_dir. Returns the relative file path for client retrieval.
    """
    annotated = image.copy()
    os.makedirs(output_dir, exist_ok=True)
    
    # Green box for pests
    pest_color = (0, 180, 0)
    # Orange/Red box for diseases
    disease_color = (0, 100, 230)
    
    all_items = [("pest", d, pest_color) for d in pest_detections] + [("disease", d, disease_color) for d in disease_detections]
    
    for kind, det, color in all_items:
        bbox = det.get("bbox")
        if not bbox:
            continue
            
        x1 = int(bbox["x1"])
        y1 = int(bbox["y1"])
        x2 = int(bbox["x2"])
        y2 = int(bbox["y2"])
        
        confidence_pct = int(det["confidence"] * 100)
        label = f"{det['name'].capitalize()} {confidence_pct}%"
        
        # Draw bounding rectangle
        cv2.rectangle(annotated, (x1, y1), (x2, y2), color, 2)
        
        # Draw label background box
        (text_w, text_h), baseline = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
        cv2.rectangle(annotated, (x1, max(0, y1 - text_h - 6)), (x1 + text_w + 4, y1), color, -1)
        
        # Draw text label
        cv2.putText(annotated, label, (x1 + 2, max(text_h, y1 - 4)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1, cv2.LINE_AA)
        
    filename = f"annotated_{uuid.uuid4().hex[:10]}.jpg"
    full_path = os.path.join(output_dir, filename)
    cv2.imwrite(full_path, annotated)
    
    return f"/results/{filename}"
