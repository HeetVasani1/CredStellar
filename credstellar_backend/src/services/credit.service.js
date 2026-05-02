// ============================================
// Credit Service
// Fetches credit account data for a user
// ============================================

const supabase = require('../config/supabase');

/**
 * Get credit summary for a user
 * available is ALWAYS computed dynamically: total - used
 */
async function getSummary(userId) {
  const { data, error } = await supabase
    .from('credit_accounts')
    .select('*')
    .eq('user_id', userId)
    .single();

  if (error || !data) {
    // No credit account yet — return zeroes
    return {
      total_credit_limit: 0,
      used_balance: 0,
      available: 0,
    };
  }

  const totalLimit = parseFloat(data.total_credit_limit) || 0;
  const usedBalance = parseFloat(data.used_balance) || 0;
  const available = parseFloat((totalLimit - usedBalance).toFixed(2));

  return {
    total_credit_limit: totalLimit,
    used_balance: usedBalance,
    available,
  };
}

module.exports = { getSummary };
