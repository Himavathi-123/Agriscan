import time

def format_infer_response(
    pests: list,
    diseases: list,
    img_width: int,
    img_height: int,
    start_time: float,
    annotated_image_url: str = None,
    pest_ok: bool = True,
    disease_ok: bool = True
) -> dict:
    processing_time_ms = int((time.time() - start_time) * 1000)
    pest_count = len(pests)
    disease_count = len(diseases)
    
    status = "DETECTION_FOUND" if (pest_count > 0 or disease_count > 0) else "NO_CONFIDENT_DETECTION"
    
    return {
        "success": True,
        "processingTimeMs": processing_time_ms,
        "image": {
            "width": img_width,
            "height": img_height
        },
        "detections": {
            "pests": pests,
            "diseases": diseases
        },
        "summary": {
            "pestCount": pest_count,
            "diseaseCount": disease_count
        },
        "status": status,
        "modelStatus": {
            "pest": "ok" if pest_ok else "unavailable",
            "disease": "ok" if disease_ok else "unavailable"
        },
        "annotatedImage": annotated_image_url
    }
