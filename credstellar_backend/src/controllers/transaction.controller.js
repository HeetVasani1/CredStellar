// ============================================
// Transaction Controller
// Thin layer — delegates to transaction.service.js
// ============================================

const { asyncHandler } = require('../utils/helpers');
const transactionService = require('../services/transaction.service');

// GET /api/transactions
const getAll = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const transactions = await transactionService.getAll(userId);

  res.json({
    success: true,
    message: 'Transactions fetched.',
    data: { transactions, count: transactions.length },
  });
});

// GET /api/transactions/:id
const getById = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const txId = req.params.id;
  const transaction = await transactionService.getById(userId, txId);

  res.json({
    success: true,
    data: { transaction },
  });
});

// GET /api/transactions/export — placeholder
const exportCsv = asyncHandler(async (req, res) => {
  res.status(501).json({ success: false, error: 'Not implemented yet' });
});

module.exports = { getAll, getById, exportCsv };
