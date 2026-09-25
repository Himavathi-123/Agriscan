# AgriScan Optimization TODO
Optimized iteratively without losing features. Current progress:

## Completed (6/9)
- [x] 0. Created TODO.md
- [x] 1. Update pubspec.yaml (optimized deps, cached_network_image added, Firebase removed)
- [x] 2. flutter pub get (run manually in VSCode terminal: cd pest_F1_app && flutter pub get)
- [x] 3. Backend: app.py debug=False + threaded=True
- [x] 4. Backend: requirements.txt lighter deps (tflite-runtime, headless opencv)
- [x] 5. Android: build.gradle.kts.new with R8/minify/shrink (manual replace needed)
- [ ] 6. Replace pest_F1_app/android/app/build.gradle.kts with build.gradle.kts.new
- [ ] 7. Backend test: cd backend && pip install -r requirements.txt && python app.py (verify /predict)
- [ ] 8. Flutter test: cd pest_F1_app && flutter run (check perf)
- [ ] 9. Build: cd pest_F1_app && flutter build apk --release (check size)
- [ ] 7. Backend test
- [ ] 8. Flutter test
- [ ] 9. Build release
