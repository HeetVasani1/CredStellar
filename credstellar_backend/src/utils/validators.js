// ============================================
// Validators — Joi schemas for request validation
// ============================================

const Joi = require('joi');

const schemas = {
  signup: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).max(128).required(),
    full_name: Joi.string().min(1).max(100).required(),
  }),

  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required(),
  }),

  createFd: Joi.object({
    amount: Joi.number().positive().required(),
    tenor_months: Joi.number().valid(3, 6, 12).required(),
  }),

  paymentPreview: Joi.object({
    amount_local: Joi.number().positive().required(),
    merchant_name: Joi.string().allow('').optional(),
  }),

  paymentExecute: Joi.object({
    amount_local: Joi.number().positive().required(),
    merchant_name: Joi.string().allow('').optional(),
  }),
};

/**
 * Middleware factory: validates req.body against a named schema
 */
const validate = (schemaName) => {
  return (req, res, next) => {
    const schema = schemas[schemaName];
    if (!schema) return next();

    const { error } = schema.validate(req.body, { abortEarly: false });
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: error.details.map((d) => d.message),
      });
    }
    next();
  };
};

module.exports = { schemas, validate };
