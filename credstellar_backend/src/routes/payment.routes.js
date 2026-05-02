// ============================================
// Payment Routes — /api/payment
// ============================================

const express = require('express');
const router = express.Router();
const authenticate = require('../middleware/auth');
const paymentController = require('../controllers/payment.controller');
const { validate } = require('../utils/validators');

// POST /api/payment/preview
router.post('/preview', authenticate, validate('paymentPreview'), paymentController.preview);

// POST /api/payment/execute
router.post('/execute', authenticate, validate('paymentExecute'), paymentController.execute);

module.exports = router;
