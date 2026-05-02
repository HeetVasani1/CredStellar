// ============================================
// Auth Routes — /api/auth
// ============================================

const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { validate } = require('../utils/validators');

// POST /api/auth/signup
router.post('/signup', validate('signup'), authController.signup);

// POST /api/auth/login
router.post('/login', validate('login'), authController.login);

module.exports = router;
