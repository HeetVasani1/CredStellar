// ============================================
// Transaction Routes — /api/transactions
// ============================================

const express = require('express');
const router = express.Router();
const authenticate = require('../middleware/auth');
const transactionController = require('../controllers/transaction.controller');

// GET /api/transactions
router.get('/', authenticate, transactionController.getAll);

// GET /api/transactions/export
router.get('/export', authenticate, transactionController.exportCsv);

// GET /api/transactions/:id
router.get('/:id', authenticate, transactionController.getById);

module.exports = router;
