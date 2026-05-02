// ============================================
// Transaction Service
// List + detail retrieval for user transactions
// ============================================

const supabase = require('../config/supabase');
const { AppError } = require('../utils/helpers');

/**
 * Get all transactions for a user, sorted by latest first
 * @param {string} userId
 * @returns {Array} transactions
 */
async function getAll(userId) {
  const { data, error } = await supabase
    .from('transactions')
    .select('id, type, merchant_name, amount_usd, amount_local, local_currency, amount_xlm, status, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });

  if (error) {
    throw new AppError(`Failed to fetch transactions: ${error.message}`, 500);
  }

  return (data || []).map((tx) => ({
    id: tx.id,
    type: tx.type,
    merchant_name: tx.merchant_name,
    amount_usd: tx.amount_usd ? parseFloat(tx.amount_usd) : null,
    amount_local: tx.amount_local ? parseFloat(tx.amount_local) : null,
    local_currency: tx.local_currency,
    amount_xlm: tx.amount_xlm ? parseFloat(tx.amount_xlm) : null,
    status: tx.status,
    created_at: tx.created_at,
  }));
}

/**
 * Get a single transaction by ID (must belong to user)
 * @param {string} userId
 * @param {string} txId
 * @returns {object} transaction
 */
async function getById(userId, txId) {
  const { data, error } = await supabase
    .from('transactions')
    .select('*')
    .eq('id', txId)
    .eq('user_id', userId)
    .single();

  if (error || !data) {
    throw new AppError('Transaction not found.', 404);
  }

  return {
    id: data.id,
    type: data.type,
    merchant_name: data.merchant_name,
    merchant_category: data.merchant_category,
    amount_usd: data.amount_usd ? parseFloat(data.amount_usd) : null,
    amount_local: data.amount_local ? parseFloat(data.amount_local) : null,
    local_currency: data.local_currency,
    amount_xlm: data.amount_xlm ? parseFloat(data.amount_xlm) : null,
    fx_rate: data.fx_rate ? parseFloat(data.fx_rate) : null,
    stellar_tx_hash: data.stellar_tx_hash,
    stellar_fee_xlm: data.stellar_fee_xlm ? parseFloat(data.stellar_fee_xlm) : null,
    status: data.status,
    notes: data.notes,
    location: data.location,
    created_at: data.created_at,
  };
}

module.exports = { getAll, getById };
