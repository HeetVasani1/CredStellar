// ============================================
// Payment Controller
// Thin layer — delegates to payment.service.js
// ============================================

const { asyncHandler } = require('../utils/helpers');
const paymentService = require('../services/payment.service');

// POST /api/payment/preview
const preview = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { amount_local, merchant_name } = req.body;

  const result = await paymentService.preview(userId, {
    amount_local,
    merchant_name,
  });

  res.json({
    success: true,
    message: 'Payment preview generated.',
    data: result,
  });
});

// POST /api/payment/execute
const execute = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { amount_local, merchant_name } = req.body;

  const result = await paymentService.execute(userId, {
    amount_local,
    merchant_name,
  });

  res.status(201).json({
    success: true,
    message: 'Payment executed successfully.',
    data: result,
  });
});

module.exports = { preview, execute };
