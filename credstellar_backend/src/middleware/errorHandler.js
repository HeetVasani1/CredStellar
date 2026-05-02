// ============================================
// Global Error Handler Middleware
// Catches all unhandled errors uniformly
// ============================================

const config = require('../config/env');

const errorHandler = (err, req, res, next) => {
  console.error(`[ERROR] ${err.message}`);

  if (config.nodeEnv === 'development') {
    console.error(err.stack);
  }

  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  res.status(statusCode).json({
    success: false,
    error: message,
    ...(config.nodeEnv === 'development' && { stack: err.stack }),
  });
};

module.exports = errorHandler;
