// ============================================
// FX Service
// Live currency conversion: USD ↔ INR ↔ XLM
// Uses free ExchangeRate API
// ============================================

const config = require('../config/env');
const { AppError } = require('../utils/helpers');

// Cache rates for 5 minutes to avoid excessive API calls
let rateCache = {
  rates: null,
  fetchedAt: 0,
};
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

/**
 * Fetches live FX rates from free API (base = USD)
 * Returns { INR: 83.02, XLM: ... }
 */
async function fetchRates() {
  const now = Date.now();

  // Return cached if still valid
  if (rateCache.rates && (now - rateCache.fetchedAt) < CACHE_TTL_MS) {
    return rateCache.rates;
  }

  try {
    const response = await fetch(config.fx.apiUrl);

    if (!response.ok) {
      throw new Error(`FX API returned ${response.status}`);
    }

    const data = await response.json();
    rateCache = { rates: data.rates, fetchedAt: now };
    console.log('[FX] Rates refreshed from live API');
    return data.rates;
  } catch (err) {
    console.error(`[FX] API fetch failed: ${err.message}`);

    // Fallback to hardcoded rates if API fails
    const fallback = { INR: 83.02, XLM: 8.33, EUR: 0.92, GBP: 0.79 };
    console.warn('[FX] Using fallback hardcoded rates');
    return fallback;
  }
}

/**
 * Converts INR → USD
 */
async function inrToUsd(amountInr) {
  const rates = await fetchRates();
  const inrRate = rates.INR;
  if (!inrRate) throw new AppError('INR rate unavailable', 500);
  return parseFloat((amountInr / inrRate).toFixed(2));
}

/**
 * Converts USD → INR
 */
async function usdToInr(amountUsd) {
  const rates = await fetchRates();
  const inrRate = rates.INR;
  if (!inrRate) throw new AppError('INR rate unavailable', 500);
  return parseFloat((amountUsd * inrRate).toFixed(2));
}

/**
 * Converts USD → XLM
 */
async function usdToXlm(amountUsd) {
  const rates = await fetchRates();
  const xlmRate = rates.XLM;
  if (!xlmRate) throw new AppError('XLM rate unavailable', 500);
  return parseFloat((amountUsd * xlmRate).toFixed(7));
}

/**
 * Gets the current USD → INR rate
 */
async function getUsdToInrRate() {
  const rates = await fetchRates();
  return rates.INR || 83.02;
}

/**
 * Gets the current USD → XLM rate
 */
async function getUsdToXlmRate() {
  const rates = await fetchRates();
  return rates.XLM || 8.33;
}

module.exports = {
  fetchRates,
  inrToUsd,
  usdToInr,
  usdToXlm,
  getUsdToInrRate,
  getUsdToXlmRate,
};
