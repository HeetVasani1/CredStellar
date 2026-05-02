// ============================================
// Stellar SDK Config
// Initializes Stellar SDK for testnet
// ============================================

const StellarSdk = require('@stellar/stellar-sdk');
const config = require('./env');

// Point to testnet horizon server
const server = new StellarSdk.Horizon.Server(config.stellar.horizonUrl);

// Use testnet network passphrase
const networkPassphrase = StellarSdk.Networks.TESTNET;

module.exports = {
  StellarSdk,
  server,
  networkPassphrase,
};
