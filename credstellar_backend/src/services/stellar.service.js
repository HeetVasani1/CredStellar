// ============================================
// Stellar Service
// Keypair generation + testnet funding + tx simulation
// ============================================

const { StellarSdk, server, networkPassphrase } = require('../config/stellar');
const config = require('../config/env');
const crypto = require('crypto');

/**
 * Generates a new Stellar keypair
 * @returns {{ publicKey: string, secretKey: string }}
 */
function generateKeypair() {
  const pair = StellarSdk.Keypair.random();
  return {
    publicKey: pair.publicKey(),
    secretKey: pair.secret(),
  };
}

/**
 * Funds a testnet account using Friendbot
 * @param {string} publicKey - Stellar public key to fund
 * @returns {Promise<boolean>} - true if funded successfully
 */
async function fundTestnetAccount(publicKey) {
  try {
    const response = await fetch(
      `${config.stellar.friendbotUrl}?addr=${encodeURIComponent(publicKey)}`
    );

    if (!response.ok) {
      console.warn(`[Stellar] Friendbot funding failed for ${publicKey}: ${response.status}`);
      return false;
    }

    console.log(`[Stellar] Funded testnet account: ${publicKey}`);
    return true;
  } catch (err) {
    console.error(`[Stellar] Friendbot error:`, err.message);
    return false;
  }
}

/**
 * Simulates a Stellar payment transaction.
 * Generates a realistic 64-char hex tx hash.
 *
 * In production, this would:
 * 1. Load sender account from Horizon
 * 2. Build a payment operation
 * 3. Sign with sender's secret key
 * 4. Submit to Stellar network
 *
 * @param {{ senderPublicKey: string, amountXlm: number, merchantName: string }} params
 * @returns {{ tx_hash: string, ledger: number, fee_xlm: number, timestamp: string }}
 */
async function simulatePayment({ senderPublicKey, amountXlm, merchantName }) {
  const txHash = crypto
    .createHash('sha256')
    .update(`${senderPublicKey}-${amountXlm}-${merchantName}-${Date.now()}-${crypto.randomBytes(16).toString('hex')}`)
    .digest('hex');

  const ledger = Math.floor(Math.random() * 1000000) + 50000000;

  const result = {
    tx_hash: txHash,
    ledger: ledger,
    fee_xlm: 0.00001,
    timestamp: new Date().toISOString(),
    network: config.stellar.network,
  };

  console.log(`[Stellar] Simulated tx: ${txHash.substring(0, 16)}... for ${amountXlm} XLM`);
  return result;
}

module.exports = {
  generateKeypair,
  fundTestnetAccount,
  simulatePayment,
};
