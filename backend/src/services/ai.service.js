const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || 'http://127.0.0.1:8000';

class AIService {
  /**
   * Forwards uploaded image to Python AI Inference microservice (/infer)
   */
  async runInference(filePath, originalFilename, mimeType, options = {}) {
    const formData = new FormData();
    formData.append('image', fs.createReadStream(filePath), {
      filename: originalFilename || 'crop_image.jpg',
      contentType: mimeType || 'image/jpeg'
    });

    if (options.pestConfidence) {
      formData.append('pest_confidence', options.pestConfidence.toString());
    }
    if (options.diseaseConfidence) {
      formData.append('disease_confidence', options.diseaseConfidence.toString());
    }

    try {
      const response = await axios.post(`${AI_SERVICE_URL}/infer`, formData, {
        headers: {
          ...formData.getHeaders()
        },
        timeout: 30000 // 30 second timeout
      });

      return response.data;
    } catch (error) {
      if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
        const err = new Error('AI inference service is currently unavailable. Please try again later.');
        err.code = 'AI_SERVICE_UNAVAILABLE';
        err.status = 503;
        throw err;
      }

      if (error.response) {
        const err = new Error(error.response.data?.detail || 'AI inference microservice error.');
        err.code = 'AI_INFERENCE_ERROR';
        err.status = error.response.status || 500;
        throw err;
      }

      const err = new Error('Failed to communicate with AI inference microservice.');
      err.code = 'AI_COMMUNICATION_ERROR';
      err.status = 500;
      throw err;
    } finally {
      // Clean up temporary upload file
      if (filePath && fs.existsSync(filePath)) {
        try {
          fs.unlinkSync(filePath);
        } catch (cleanupErr) {
          console.error(`Failed to clean up temp file ${filePath}:`, cleanupErr.message);
        }
      }
    }
  }

  /**
   * Fetches health status from Python AI microservice (/health)
   */
  async getHealth() {
    try {
      const response = await axios.get(`${AI_SERVICE_URL}/health`, { timeout: 5000 });
      return response.data;
    } catch (error) {
      return {
        status: 'unavailable',
        models: { pest: false, disease: false },
        device: 'unknown',
        error: 'Python AI service unreachable'
      };
    }
  }
}

module.exports = new AIService();
