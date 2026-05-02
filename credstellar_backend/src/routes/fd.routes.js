// ============================================
// Fixed Deposit Routes — /api/fd
// ============================================

const express = require('express');
const router = express.Router();
const authenticate = require('../middleware/auth');
const fdController = require('../controllers/fd.controller');
const { validate } = require('../utils/validators');

// POST /api/fd/create
router.post('/create', authenticate, validate('createFd'), fdController.create);

// GET /api/fd/list
router.get('/list', authenticate, fdController.getList);

// GET /api/fd/:id
router.get('/:id', authenticate, fdController.getById);

module.exports = router;
