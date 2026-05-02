// ============================================
// Auth Service
// Handles signup and login business logic
// ============================================

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const supabase = require('../config/supabase');
const config = require('../config/env');
const { AppError, encrypt } = require('../utils/helpers');
const stellarService = require('./stellar.service');

const SALT_ROUNDS = 12;

/**
 * Generates a JWT token for a user
 * @param {{ id: string, email: string }} user
 * @returns {string} JWT token
 */
function generateToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn }
  );
}

/**
 * Signup — creates user, wallet, Stellar keypair, credit account
 * @param {{ email: string, password: string, full_name: string }} data
 * @returns {{ user: object, token: string }}
 */
async function signup({ email, password, full_name }) {
  // 1. Check if user already exists
  const { data: existing } = await supabase
    .from('users')
    .select('id')
    .eq('email', email)
    .single();

  if (existing) {
    throw new AppError('An account with this email already exists.', 409);
  }

  // 2. Hash password
  const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

  // 3. Create user record
  const { data: user, error: userError } = await supabase
    .from('users')
    .insert({ email, password_hash, full_name })
    .select('id, email, full_name, created_at')
    .single();

  if (userError) {
    throw new AppError(`Failed to create user: ${userError.message}`, 500);
  }

  // 4. Generate Stellar keypair
  const { publicKey, secretKey } = stellarService.generateKeypair();
  const encryptedSecret = encrypt(secretKey);

  // 5. Create wallet record
  const { error: walletError } = await supabase
    .from('wallets')
    .insert({
      user_id: user.id,
      balance_usd: 0,
      balance_xlm: 0,
      stellar_public_key: publicKey,
      stellar_secret_key_enc: encryptedSecret,
    });

  if (walletError) {
    // Rollback: delete the user if wallet creation fails
    await supabase.from('users').delete().eq('id', user.id);
    throw new AppError(`Failed to create wallet: ${walletError.message}`, 500);
  }

  // 6. Create empty credit account
  const { error: creditError } = await supabase
    .from('credit_accounts')
    .insert({
      user_id: user.id,
      total_credit_limit: 0,
      used_balance: 0,
    });

  if (creditError) {
    // Rollback: delete wallet and user if credit account creation fails
    await supabase.from('wallets').delete().eq('user_id', user.id);
    await supabase.from('users').delete().eq('id', user.id);
    throw new AppError(`Failed to create credit account: ${creditError.message}`, 500);
  }

  // 7. Fund Stellar testnet account (async, non-blocking)
  stellarService.fundTestnetAccount(publicKey).catch((err) => {
    console.error(`[Auth] Friendbot funding failed: ${err.message}`);
  });

  // 8. Generate JWT
  const token = generateToken(user);

  return {
    user: {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      stellar_public_key: publicKey,
      created_at: user.created_at,
    },
    token,
  };
}

/**
 * Login — validates credentials and returns JWT
 * @param {{ email: string, password: string }} data
 * @returns {{ user: object, token: string }}
 */
async function login({ email, password }) {
  // 1. Find user by email
  const { data: user, error } = await supabase
    .from('users')
    .select('id, email, full_name, password_hash, created_at')
    .eq('email', email)
    .single();

  if (error || !user) {
    throw new AppError('Invalid email or password.', 401);
  }

  // 2. Compare password
  const isMatch = await bcrypt.compare(password, user.password_hash);
  if (!isMatch) {
    throw new AppError('Invalid email or password.', 401);
  }

  // 3. Fetch wallet for Stellar public key
  const { data: wallet } = await supabase
    .from('wallets')
    .select('stellar_public_key')
    .eq('user_id', user.id)
    .single();

  // 4. Generate JWT
  const token = generateToken(user);

  return {
    user: {
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      stellar_public_key: wallet?.stellar_public_key || null,
      created_at: user.created_at,
    },
    token,
  };
}

module.exports = { signup, login };
