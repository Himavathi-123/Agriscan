# AgriScan Setup Guide

Follow these instructions to set up and run the AgriScan project on a new laptop.

## Prerequisites

- **Python 3.8+**
- **Flutter SDK** (and Dart)
- **Git**
- **VS Code** (recommended) or any other IDE

---

## 1. Backend Setup (Flask API)

The backend provides the AI prediction service using a TFLite model.

1.  **Navigate to the backend directory:**
    ```bash
    cd backend
    ```

2.  **Create a virtual environment:**
    ```bash
    python -m venv venv
    ```

3.  **Activate the virtual environment:**
    - **Windows:** `venv\Scripts\activate`
    - **macOS/Linux:** `source venv/bin/activate`

4.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

5.  **Run the server:**
    ```bash
    python app.py
    ```
    *The server will start at `http://127.0.0.1:5000`.*

---

## 2. Frontend Setup (Flutter App)

The frontend is a Flutter mobile application.

1.  **Navigate to the frontend directory:**
    ```bash
    cd pest_F1_app
    ```

2.  **Get dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration (Important):**
    - This project uses Firebase (Auth, Firestore, Storage).
    - You MUST add your own `google-services.json` (for Android) to `android/app/` and `GoogleService-Info.plist` (for iOS) to `ios/Runner/`.
    - Alternatively, run `flutterfire configure` if you have the FlutterFire CLI installed.

4.  **Run the app:**
    - Connect a physical device or start an emulator.
    - Run:
      ```bash
      flutter run
      ```

---

## 3. Project Structure

- `backend/`: Python Flask server and AI model (`rice_pest_model.tflite`).
- `pest_F1_app/`: Flutter mobile application code.
- `dataset/`: (Optional) Data used for training or reference.

## Troubleshooting

- **Python Errors:** Ensure you are using a 64-bit version of Python for TensorFlow compatibility.
- **Flutter Build Errors:** Run `flutter clean` then `flutter pub get` if you encounter dependency issues.
- **Backend Connection:** If running the app on a physical device, change the API URL in the Flutter code from `localhost` or `127.0.0.1` to your laptop's local IP address (e.g., `192.168.1.XX`).
