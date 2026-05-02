// ============================================
// CredStellar Backend — Express Entry Point
// ============================================

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const config = require('./config/env');
const errorHandler = require('./middleware/errorHandler');

// Import routes
const authRoutes = require('./routes/auth.routes');
const creditRoutes = require('./routes/credit.routes');
const fdRoutes = require('./routes/fd.routes');
const paymentRoutes = require('./routes/payment.routes');
const transactionRoutes = require('./routes/transaction.routes');

const app = express();

// ---- Global Middleware ----
app.use(helmet());                          // Security headers
app.use(cors());                            // Enable CORS for Flutter app
app.use(express.json({ limit: '10mb' }));   // Parse JSON bodies
app.use(express.urlencoded({ extended: true }));

// Request logging (dev only)
if (config.nodeEnv === 'development') {
  app.use(morgan('dev'));
}

// ---- Health Check ----
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'CredStellar API is running',
    environment: config.nodeEnv,
    timestamp: new Date().toISOString(),
  });
});

// ---- API Routes ----
app.use('/api/auth', authRoutes);
app.use('/api/credit', creditRoutes);
app.use('/api/fd', fdRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/transactions', transactionRoutes);

// ---- 404 Handler ----
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: `Route ${req.method} ${req.originalUrl} not found`,
  });
});

// ---- Global Error Handler (must be last) ----
app.use(errorHandler);

// ---- Start Server ----
app.listen(config.port, () => {
  console.log(`
  ╔══════════════════════════════════════════╗
  ║   CredStellar API Server                ║
  ║   Port: ${config.port}                          ║
  ║   Env:  ${config.nodeEnv.padEnd(29)}║
  ╚══════════════════════════════════════════╝
  `);
});

module.exports = app;
