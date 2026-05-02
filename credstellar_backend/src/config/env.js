// ============================================
// Environment Config
// Loads .env and exports typed config object
// ============================================

const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const config = {
  port: parseInt(process.env.PORT, 10) || 3000,
  nodeEnv: process.env.NODE_ENV || 'development',

  supabase: {
    url: process.env.SUPABASE_URL,
    anonKey: process.env.SUPABASE_ANON_KEY,
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  },

  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },

  stellar: {
    network: process.env.STELLAR_NETWORK || 'testnet',
    horizonUrl: process.env.STELLAR_HORIZON_URL,
    friendbotUrl: process.env.STELLAR_FRIENDBOT_URL,
  },

  fx: {
    apiUrl: process.env.FX_API_URL,
  },

  encryption: {
    key: process.env.ENCRYPTION_KEY,
  },
};

module.exports = config;
