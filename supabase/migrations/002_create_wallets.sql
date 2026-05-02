-- ============================================
-- Migration 002: Wallets Table
-- Internal balance + Stellar keypair per user
-- ============================================

CREATE TABLE IF NOT EXISTS wallets (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  balance_usd           DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  balance_xlm           DECIMAL(18,7) NOT NULL DEFAULT 0.0000000,
  stellar_public_key    TEXT,
  stellar_secret_key_enc TEXT,  -- AES-encrypted, never exposed to frontend
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- One wallet per user, fast lookup
CREATE INDEX idx_wallets_user_id ON wallets (user_id);

-- Prevent negative balances
ALTER TABLE wallets
  ADD CONSTRAINT chk_wallets_balance_usd CHECK (balance_usd >= 0),
  ADD CONSTRAINT chk_wallets_balance_xlm CHECK (balance_xlm >= 0);

CREATE TRIGGER trg_wallets_updated_at
  BEFORE UPDATE ON wallets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
