const aiService = require('../services/ai.service');

class DetectionController {
  async detect(req, res, next) {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'MISSING_IMAGE_FILE',
            message: 'No image file was provided in the request payload.'
          }
        });
      }

      const pestConf = req.body.pest_confidence ? parseFloat(req.body.pest_confidence) : undefined;
      const diseaseConf = req.body.disease_confidence ? parseFloat(req.body.disease_confidence) : undefined;
      const modelId = req.body.model_id || 'ip102_pests_102';

      const modelNameMap = {
        'rice_pests': 'Rice Pest Classifier',
        'ip102_pests_102': 'All Agricultural Pests (102 Species)',
        'plant_diseases_38': 'Plant Diseases (38 Conditions)'
      };
      const modelName = modelNameMap[modelId] || 'AgriScan AI Model';

      const aiResult = await aiService.runInference(
        req.file.path,
        req.file.originalname,
        req.file.mimetype,
        { pestConfidence: pestConf, diseaseConfidence: diseaseConf }
      );

      // Prepend AI_SERVICE_URL to annotated image URL if present
      let annotatedImageUrl = aiResult.annotatedImage;
      if (annotatedImageUrl && !annotatedImageUrl.startsWith('http')) {
        const aiUrl = process.env.AI_SERVICE_URL || 'http://localhost:8000';
        annotatedImageUrl = `${aiUrl}${annotatedImageUrl}`;
      }

      const pests = aiResult.detections?.pests || [];
      const diseases = aiResult.detections?.diseases || [];
      const allDetections = [...pests, ...diseases].sort((a, b) => b.confidence - a.confidence);
      const topItem = allDetections.length > 0 ? allDetections[0] : null;

      let statusCategory = 'Healthy';
      let statusText = 'Healthy Crop — No pest or disease detected';
      let issueName = 'Healthy Crop';
      let topConfidence = 0.0;
      let confidencePct = '0%';

      if (topItem) {
        topConfidence = topItem.confidence;
        confidencePct = `${Math.round(topConfidence * 100)}%`;
        
        if (topConfidence >= 0.35) {
          statusCategory = 'Unhealthy';
          issueName = topItem.name;
          statusText = `Unhealthy (${issueName})`;
        } else {
          statusCategory = 'Invalid';
          issueName = 'Low Confidence / Invalid';
          statusText = 'Low confidence (< 35%). Please upload a clearer leaf photo.';
        }
      }

      return res.status(200).json({
        success: true,
        data: {
          status_category: statusCategory,
          status_text: statusText,
          issue_name: issueName,
          confidence: topConfidence,
          confidence_pct: confidencePct,
          model_id: modelId,
          model_name: modelName,
          pests: pests,
          diseases: diseases,
          summary: aiResult.summary || { pestCount: pests.length, diseaseCount: diseases.length },
          status: aiResult.status || 'NO_CONFIDENT_DETECTION',
          annotatedImage: annotatedImageUrl,
          processingTimeMs: aiResult.processingTimeMs
        }
      });
    } catch (error) {
      next(error);
    }
  }

  async health(req, res) {
    const aiHealth = await aiService.getHealth();
    
    return res.status(200).json({
      status: 'ok',
      backend: 'Node.js Express',
      aiService: aiHealth
    });
  }
}

module.exports = new DetectionController();
