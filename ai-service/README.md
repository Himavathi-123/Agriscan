# AgriScan AI Inference Microservice

Lightweight Python FastAPI service responsible for loading AI models once at startup and serving crop pest and disease detection requests.

## Architecture

- **Pest Model**: Pretrained YOLO11s trained on 102 IP102 pest categories (`underdogquality/yolo11s-pest-detection`). Automatically downloaded from Hugging Face on initial launch if not found at `./models/pest/best.pt`.
- **Disease Model**: PlantDoc-based disease classifier/detector (`./models/disease/disease_model.pt`). If checkpoint is not present, runs in degraded mode returning empty disease detections.
- **Hardware Acceleration**: Automatic CUDA GPU detection (`torch.cuda.is_available()`), with CPU fallback.

## Setup & Running

1. **Create Virtual Environment**:
   ```bash
   python -m venv .venv
   ```

2. **Activate Environment**:
   - **Windows**: `.venv\Scripts\activate`
   - **macOS/Linux**: `source .venv/bin/activate`

3. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

4. **Run Server**:
   ```bash
   python app.py
   ```
   *Service starts on `http://localhost:8000`.*

## Endpoints

- `GET /health`: Health check and model loading status.
- `POST /infer`: Expects `multipart/form-data` with `image`. Accepts optional `pest_confidence` and `disease_confidence`.
