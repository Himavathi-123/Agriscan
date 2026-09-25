const express = require('express');
const router = express.Router();
const detectionController = require('../controllers/detection.controller');
const { uploadImage } = require('../middleware/upload.middleware');

router.post('/detect', uploadImage, (req, res, next) => detectionController.detect(req, res, next));
router.get('/health', (req, res) => detectionController.health(req, res));

module.exports = router;
