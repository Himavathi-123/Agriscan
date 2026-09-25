const geminiService = require('../services/gemini.service');

class ExplanationController {
  async explain(req, res, next) {
    try {
      const { crop = 'crop', detections = { pests: [], diseases: [] } } = req.body || {};

      const result = await geminiService.generateExplanation(crop, detections);

      return res.status(200).json({
        success: true,
        data: result
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ExplanationController();
