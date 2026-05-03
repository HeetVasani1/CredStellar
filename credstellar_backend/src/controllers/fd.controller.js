// ============================================
// Fixed Deposit Controller
// Thin layer — delegates to fd.service.js
// ============================================

const { asyncHandler } = require('../utils/helpers');
const fdService = require('../services/fd.service');

// POST /api/fd/create
const create = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { amount, tenor_months } = req.body;

  const result = await fdService.createFd(userId, { amount, tenor_months });

  res.status(201).json({
    success: true,
    message: 'Fixed Deposit created successfully. Credit limit updated.',
    data: result,
  });
});

// GET /api/fd/list
const getList = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const fds = await fdService.getList(userId);
  res.status(200).json({ success: true, data: { fixed_deposits: fds } });
});

// GET /api/fd/:id — placeholder
const getById = asyncHandler(async (req, res) => {
  res.status(501).json({ success: false, error: 'Not implemented yet' });
});

module.exports = { create, getList, getById };
