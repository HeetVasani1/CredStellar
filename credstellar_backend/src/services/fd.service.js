// ============================================
// FD Service
// FD creation + credit limit recalculation
// ============================================

const supabase = require('../config/supabase');
const { AppError } = require('../utils/helpers');

// Hardcoded APY rates for MVP (by tenor)
const APY_RATES = {
  3: 4.15,
  6: 4.50,
  12: 5.25,
};

// FD naming pool
const FD_NAMES = [
  'Stellar Vault Alpha',
  'Yield Lock Beta',
  'Reserve Prime',
  'Stability Ledger IV',
  'Horizon Safe',
  'Nova Shield',
  'Orbit Yield',
  'Apex Reserve',
];

/**
 * Picks a random FD name
 */
function generateFdName() {
  return FD_NAMES[Math.floor(Math.random() * FD_NAMES.length)];
}

/**
 * Calculates maturity date from today + tenor months
 */
function calculateMaturityDate(tenorMonths) {
  const date = new Date();
  date.setMonth(date.getMonth() + tenorMonths);
  return date.toISOString().split('T')[0]; // YYYY-MM-DD
}

/**
 * Calculates simple estimated interest
 * interest = principal × (apy / 100) × (tenor / 12)
 */
function calculateEstimatedInterest(principal, apyRate, tenorMonths) {
  return parseFloat((principal * (apyRate / 100) * (tenorMonths / 12)).toFixed(2));
}

/**
 * Creates a new Fixed Deposit and updates the credit limit
 * @param {string} userId
 * @param {{ amount: number, tenor_months: number }} data
 */
async function createFd(userId, { amount, tenor_months }) {
  const apyRate = APY_RATES[tenor_months];
  if (!apyRate) {
    throw new AppError('Invalid tenor. Must be 3, 6, or 12 months.', 400);
  }

  const maturityDate = calculateMaturityDate(tenor_months);
  const estimatedInterest = calculateEstimatedInterest(amount, apyRate, tenor_months);

  // 1. Insert FD record
  const { data: fd, error: fdError } = await supabase
    .from('fixed_deposits')
    .insert({
      user_id: userId,
      name: generateFdName(),
      principal_amount: amount,
      currency: 'USD',
      apy_rate: apyRate,
      tenor_months: tenor_months,
      maturity_date: maturityDate,
      estimated_interest: estimatedInterest,
      status: 'active',
    })
    .select()
    .single();

  if (fdError) {
    throw new AppError(`Failed to create FD: ${fdError.message}`, 500);
  }

  // 2. Fetch current credit account
  const { data: credit, error: creditFetchError } = await supabase
    .from('credit_accounts')
    .select('id, total_credit_limit, used_balance')
    .eq('user_id', userId)
    .single();

  if (creditFetchError || !credit) {
    throw new AppError('Credit account not found.', 404);
  }

  // 3. Update credit limit (add FD amount)
  const newLimit = parseFloat((parseFloat(credit.total_credit_limit) + amount).toFixed(2));

  const { data: updatedCredit, error: creditUpdateError } = await supabase
    .from('credit_accounts')
    .update({ total_credit_limit: newLimit })
    .eq('user_id', userId)
    .select('total_credit_limit, used_balance')
    .single();

  if (creditUpdateError) {
    throw new AppError(`Failed to update credit limit: ${creditUpdateError.message}`, 500);
  }

  // 4. Record FD creation as a transaction
  await supabase.from('transactions').insert({
    user_id: userId,
    type: 'fd_creation',
    merchant_name: fd.name,
    amount_usd: amount,
    status: 'cleared',
    notes: `${tenor_months}-month FD at ${apyRate}% APY`,
  });

  return {
    fixed_deposit: {
      id: fd.id,
      name: fd.name,
      principal_amount: fd.principal_amount,
      currency: fd.currency,
      apy_rate: fd.apy_rate,
      tenor_months: fd.tenor_months,
      maturity_date: fd.maturity_date,
      estimated_interest: fd.estimated_interest,
      total_payout: parseFloat((amount + estimatedInterest).toFixed(2)),
      status: fd.status,
      created_at: fd.created_at,
    },
    credit: {
      total_credit_limit: parseFloat(updatedCredit.total_credit_limit),
      used_balance: parseFloat(updatedCredit.used_balance),
      available: parseFloat((parseFloat(updatedCredit.total_credit_limit) - parseFloat(updatedCredit.used_balance)).toFixed(2)),
    },
  };
}

module.exports = { createFd };
