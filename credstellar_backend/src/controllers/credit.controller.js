// ============================================
// Credit Controller
// Handles credit summary and utilization
// ============================================

const { asyncHandler } = require('../utils/helpers');
const creditService = require('../services/credit.service');

// GET /api/credit/summary
const getSummary = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const summary = await creditService.getSummary(userId);
  res.json({ success: true, data: summary });
});

// GET /api/credit/utilization
const getUtilization = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const summary = await creditService.getSummary(userId);
  const utilization = summary.total_credit_limit > 0
    ? parseFloat(((summary.used_balance / summary.total_credit_limit) * 100).toFixed(1))
    : 0;

  let health = 'Excellent';
  if (utilization > 50) health = 'High';
  else if (utilization > 30) health = 'Good';

  res.json({
    success: true,
    data: { utilization_percent: utilization, health },
  });
});

module.exports = { getSummary, getUtilization };
