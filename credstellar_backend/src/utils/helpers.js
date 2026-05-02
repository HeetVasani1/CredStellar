// ============================================
// Helpers — Shared utility functions
// ============================================

const crypto = require('crypto');
const config = require('../config/env');

/**
 * Wraps an async route handler to catch errors automatically
 */
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

/**
 * Creates a custom error with a status code
 */
class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

// ---- Encryption (AES-256-CBC) for Stellar secret keys ----

const ALGORITHM = 'aes-256-cbc';
const IV_LENGTH = 16;

/**
 * Derives a 32-byte key from the config encryption key
 */
function getEncryptionKey() {
  return crypto
    .createHash('sha256')
    .update(config.encryption.key)
    .digest();
}

/**
 * Encrypts a plaintext string (e.g. Stellar secret key)
 * Returns "iv:encrypted" hex string
 */
function encrypt(text) {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, getEncryptionKey(), iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return iv.toString('hex') + ':' + encrypted;
}

/**
 * Decrypts an "iv:encrypted" hex string back to plaintext
 */
function decrypt(encryptedText) {
  const [ivHex, encrypted] = encryptedText.split(':');
  const iv = Buffer.from(ivHex, 'hex');
  const decipher = crypto.createDecipheriv(ALGORITHM, getEncryptionKey(), iv);
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

module.exports = { asyncHandler, AppError, encrypt, decrypt };
