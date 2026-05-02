// ============================================
// Payment Service
// Preview + Execute with rollback
// ============================================

const supabase = require('../config/supabase');
const { AppError } = require('../utils/helpers');
const fxService = require('./fx.service');
const stellarService = require('./stellar.service');

// Stellar network fee (fixed, negligible)
const STELLAR_FEE_XLM = 0.00001;

// ---- Shared FX Conversion (used by both preview and execute) ----

/**
 * Converts amount_local (INR) → USD and XLM
 * @param {number} amountLocal - amount in INR
 * @returns {{ amountUsd, amountXlm, fxRate, xlmRate }}
 */
async function convertCurrencies(amountLocal) {
  const fxRate = await fxService.getUsdToInrRate();
  const amountUsd = parseFloat((amountLocal / fxRate).toFixed(2));

  const xlmRate = await fxService.getUsdToXlmRate();
  const amountXlm = parseFloat((amountUsd * xlmRate).toFixed(7));

  return { amountUsd, amountXlm, fxRate, xlmRate };
}

// ---- Preview ----

/**
 * Payment Preview — converts currencies, checks credit, returns summary
 * Does NOT deduct anything.
 */
async function preview(userId, { amount_local, merchant_name }) {
  // 1. Fetch user's base currency from wallet
  const { data: wallet, error: walletError } = await supabase
    .from('wallets')
    .select('base_currency')
    .eq('user_id', userId)
    .single();

  if (walletError || !wallet) {
    throw new AppError('Wallet not found.', 404);
  }

  // 2. Convert currencies (shared helper)
  const { amountUsd, amountXlm, fxRate, xlmRate } = await convertCurrencies(amount_local);

  // 3. Fetch user's credit account
  const { data: credit, error: creditError } = await supabase
    .from('credit_accounts')
    .select('total_credit_limit, used_balance')
    .eq('user_id', userId)
    .single();

  if (creditError || !credit) {
    throw new AppError('Credit account not found.', 404);
  }

  const totalLimit = parseFloat(credit.total_credit_limit);
  const usedBalance = parseFloat(credit.used_balance);
  const available = parseFloat((totalLimit - usedBalance).toFixed(2));
  const canPay = amountUsd <= available;

  // 4. Return preview (no deductions)
  return {
    merchant_name: merchant_name || 'Unknown Merchant',
    amount_local: amount_local,
    local_currency: 'INR',
    amount_usd: amountUsd,
    amount_xlm: amountXlm,
    fx_rate: fxRate,
    xlm_rate: xlmRate,
    stellar_fee_xlm: STELLAR_FEE_XLM,
    credit: {
      total_credit_limit: totalLimit,
      used_balance: usedBalance,
      available: available,
    },
    can_pay: canPay,
  };
}

// ---- Execute ----

/**
 * Payment Execute — deducts credit, records transaction, simulates Stellar tx
 * Includes rollback if any step fails after credit deduction.
 */
async function execute(userId, { amount_local, merchant_name }) {
  // 1. Convert currencies (reuses same shared helper as preview)
  const { amountUsd, amountXlm, fxRate, xlmRate } = await convertCurrencies(amount_local);

  // 2. Fetch credit account
  const { data: credit, error: creditError } = await supabase
    .from('credit_accounts')
    .select('total_credit_limit, used_balance')
    .eq('user_id', userId)
    .single();

  if (creditError || !credit) {
    throw new AppError('Credit account not found.', 404);
  }

  const totalLimit = parseFloat(credit.total_credit_limit);
  const usedBalance = parseFloat(credit.used_balance);
  const available = parseFloat((totalLimit - usedBalance).toFixed(2));

  // 3. Validate sufficient credit
  if (amountUsd > available) {
    throw new AppError(
      `Insufficient credit. Available: $${available}, Required: $${amountUsd}`,
      400
    );
  }

  // 4. Deduct credit (used_balance += amountUsd)
  const newUsedBalance = parseFloat((usedBalance + amountUsd).toFixed(2));

  const { error: deductError } = await supabase
    .from('credit_accounts')
    .update({ used_balance: newUsedBalance })
    .eq('user_id', userId);

  if (deductError) {
    throw new AppError(`Failed to deduct credit: ${deductError.message}`, 500);
  }

  // 5. Simulate Stellar transaction
  let stellarResult;
  try {
    const { data: wallet } = await supabase
      .from('wallets')
      .select('stellar_public_key')
      .eq('user_id', userId)
      .single();

    stellarResult = await stellarService.simulatePayment({
      senderPublicKey: wallet?.stellar_public_key || 'unknown',
      amountXlm: amountXlm,
      merchantName: merchant_name,
    });
  } catch (stellarErr) {
    // ROLLBACK: restore credit if Stellar fails
    await supabase
      .from('credit_accounts')
      .update({ used_balance: usedBalance })
      .eq('user_id', userId);

    throw new AppError(`Stellar transaction failed. Credit restored. ${stellarErr.message}`, 500);
  }

  // 6. Record transaction
  const { data: tx, error: txError } = await supabase
    .from('transactions')
    .insert({
      user_id: userId,
      type: 'qr_payment',
      merchant_name: merchant_name || 'Unknown Merchant',
      amount_usd: amountUsd,
      amount_local: amount_local,
      local_currency: 'INR',
      amount_xlm: amountXlm,
      fx_rate: fxRate,
      stellar_tx_hash: stellarResult.tx_hash,
      stellar_fee_xlm: stellarResult.fee_xlm,
      status: 'cleared',
    })
    .select()
    .single();

  if (txError) {
    // ROLLBACK: restore credit if transaction record fails
    await supabase
      .from('credit_accounts')
      .update({ used_balance: usedBalance })
      .eq('user_id', userId);

    throw new AppError(`Failed to record transaction. Credit restored. ${txError.message}`, 500);
  }

  // 7. Return result
  const newAvailable = parseFloat((totalLimit - newUsedBalance).toFixed(2));

  return {
    transaction: {
      id: tx.id,
      type: tx.type,
      merchant_name: tx.merchant_name,
      amount_local: parseFloat(tx.amount_local),
      local_currency: tx.local_currency,
      amount_usd: parseFloat(tx.amount_usd),
      amount_xlm: parseFloat(tx.amount_xlm),
      fx_rate: parseFloat(tx.fx_rate),
      status: tx.status,
      created_at: tx.created_at,
    },
    stellar: {
      tx_hash: stellarResult.tx_hash,
      ledger: stellarResult.ledger,
      fee_xlm: stellarResult.fee_xlm,
      network: stellarResult.network,
      timestamp: stellarResult.timestamp,
    },
    credit: {
      total_credit_limit: totalLimit,
      used_balance: newUsedBalance,
      available: newAvailable,
    },
  };
}

module.exports = { preview, execute };
