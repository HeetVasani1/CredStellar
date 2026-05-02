// ============================================
// Credit Routes — /api/credit
// ============================================

const express = require('express');
const router = express.Router();
const authenticate = require('../middleware/auth');
const creditController = require('../controllers/credit.controller');

// GET /api/credit/summary
router.get('/summary', authenticate, creditController.getSummary);

// GET /api/credit/utilization
router.get('/utilization', authenticate, creditController.getUtilization);

module.exports = router;
