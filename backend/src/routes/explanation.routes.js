const express = require('express');
const router = express.Router();
const explanationController = require('../controllers/explanation.controller');

router.post('/explain', (req, res, next) => explanationController.explain(req, res, next));

module.exports = router;
