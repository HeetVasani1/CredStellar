// ============================================
// Auth Controller
// Thin layer — delegates to auth.service.js
// ============================================

const { asyncHandler } = require('../utils/helpers');
const authService = require('../services/auth.service');

// POST /api/auth/signup
const signup = asyncHandler(async (req, res) => {
  const { email, password, full_name } = req.body;

  const result = await authService.signup({ email, password, full_name });

  res.status(201).json({
    success: true,
    message: 'Account created successfully.',
    data: result,
  });
});

// POST /api/auth/login
const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const result = await authService.login({ email, password });

  res.json({
    success: true,
    message: 'Login successful.',
    data: result,
  });
});

module.exports = { signup, login };
