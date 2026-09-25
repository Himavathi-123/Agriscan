const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const detectionRoutes = require('./routes/detection.routes');
const explanationRoutes = require('./routes/explanation.routes');
const geminiService = require('./services/gemini.service');
const { uploadImage } = require('./middleware/upload.middleware');
const detectionController = require('./controllers/detection.controller');

const app = express();
const PORT = process.env.PORT || 5000;

// CORS & Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static frontend test page & uploaded files
app.use(express.static(path.join(__dirname, '../')));

// API v1 Routes
app.use('/api/v1', detectionRoutes);
app.use('/api/v1', explanationRoutes);

// Compatibility Routes for Mobile App & Web Test Bench
app.post('/predict', uploadImage, (req, res, next) => detectionController.detect(req, res, next));

app.post('/api/chat', async (req, res) => {
  const { prompt = '', context = {} } = req.body || {};
  const crop = context.crop || 'crop';
  const issue = context.display_name || context.issue_name || context.class || '';

  let detections = { pests: [], diseases: [] };
  if (issue) {
    detections.pests.push({ name: issue, confidence: 0.90 });
  }

  const result = await geminiService.generateExplanation(crop, detections);
  return res.json({
    success: true,
    reply: typeof result.explanation === 'string' ? result.explanation : JSON.stringify(result.explanation)
  });
});

app.get('/api/models', (req, res) => {
  res.json({
    success: true,
    models: [
      {
        model_id: 'rice_pests',
        name: 'Rice Pest Classifier',
        category: 'pests',
        crop_type: 'rice'
      },
      {
        model_id: 'ip102_pests_102',
        name: 'All Agricultural Pests (102 Species)',
        category: 'pests',
        crop_type: 'general_crops'
      },
      {
        model_id: 'plant_diseases_38',
        name: 'Plant Diseases (38 Conditions)',
        category: 'diseases',
        crop_type: 'multi_crop'
      }
    ]
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[Error Handler]', err);

  if (err.code === 'LIMIT_FILE_SIZE') {
    const maxMb = process.env.MAX_IMAGE_SIZE_MB || '10';
    return res.status(400).json({
      success: false,
      error: {
        code: 'IMAGE_TOO_LARGE',
        message: `Image exceeds maximum allowed size of ${maxMb}MB.`
      }
    });
  }

  const statusCode = err.status || 500;
  const errorCode = err.code || 'INTERNAL_SERVER_ERROR';
  const errorMessage = err.message || 'An unexpected error occurred on the server.';

  return res.status(statusCode).json({
    success: false,
    error: {
      code: errorCode,
      message: errorMessage
    }
  });
});

// Start Server if launched directly
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`[AgriScan Backend] Main API Server running on port ${PORT}`);
    console.log(`[AgriScan Backend] Proxying AI inference to ${process.env.AI_SERVICE_URL || 'http://localhost:8000'}`);
  });
}

module.exports = app;
