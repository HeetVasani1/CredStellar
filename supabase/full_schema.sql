-- ============================================
-- CredStellar — Full Database Schema
-- Run this ONCE in Supabase SQL Editor
-- ============================================

-- 001: Users
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name     TEXT NOT NULL,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 002: Wallets
CREATE TABLE IF NOT EXISTS wallets (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  balance_usd           DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  balance_xlm           DECIMAL(18,7) NOT NULL DEFAULT 0.0000000,
  stellar_public_key    TEXT,
  stellar_secret_key_enc TEXT,
  base_currency         TEXT NOT NULL DEFAULT 'USD',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets (user_id);

ALTER TABLE wallets
  ADD CONSTRAINT chk_wallets_balance_usd CHECK (balance_usd >= 0),
  ADD CONSTRAINT chk_wallets_balance_xlm CHECK (balance_xlm >= 0);

CREATE TRIGGER trg_wallets_updated_at
  BEFORE UPDATE ON wallets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 003: Fixed Deposits
DO $$ BEGIN
  CREATE TYPE fd_status AS ENUM ('active', 'matured', 'withdrawn');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE fd_currency AS ENUM ('USD', 'XLM');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS fixed_deposits (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name              TEXT NOT NULL,
  account_number    TEXT NOT NULL DEFAULT substring(gen_random_uuid()::text, 1, 4),
  principal_amount  DECIMAL(18,2) NOT NULL,
  currency          fd_currency NOT NULL DEFAULT 'USD',
  apy_rate          DECIMAL(5,2) NOT NULL,
  tenor_months      INT NOT NULL,
  start_date        DATE NOT NULL DEFAULT CURRENT_DATE,
  maturity_date     DATE NOT NULL,
  estimated_interest DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  status            fd_status NOT NULL DEFAULT 'active',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fd_user_id ON fixed_deposits (user_id);
CREATE INDEX IF NOT EXISTS idx_fd_status  ON fixed_deposits (status);

ALTER TABLE fixed_deposits
  ADD CONSTRAINT chk_fd_tenor CHECK (tenor_months IN (3, 6, 12)),
  ADD CONSTRAINT chk_fd_principal CHECK (principal_amount > 0),
  ADD CONSTRAINT chk_fd_apy CHECK (apy_rate > 0 AND apy_rate < 100);

CREATE TRIGGER trg_fd_updated_at
  BEFORE UPDATE ON fixed_deposits
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 004: Credit Accounts
CREATE TABLE IF NOT EXISTS credit_accounts (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  total_credit_limit  DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  used_balance        DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_credit_user_id ON credit_accounts (user_id);

ALTER TABLE credit_accounts
  ADD CONSTRAINT chk_credit_limit     CHECK (total_credit_limit >= 0),
  ADD CONSTRAINT chk_credit_used      CHECK (used_balance >= 0),
  ADD CONSTRAINT chk_credit_not_over  CHECK (used_balance <= total_credit_limit);

CREATE TRIGGER trg_credit_updated_at
  BEFORE UPDATE ON credit_accounts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 005: Transactions
DO $$ BEGIN
  CREATE TYPE tx_type AS ENUM (
    'qr_payment', 'fd_interest', 'credit_limit_change', 'fd_creation'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE tx_status AS ENUM ('pending', 'cleared', 'failed');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type              tx_type NOT NULL,
  merchant_name     TEXT,
  merchant_category TEXT,
  amount_usd        DECIMAL(18,2),
  amount_local      DECIMAL(18,2),
  local_currency    TEXT NOT NULL DEFAULT 'INR',
  amount_xlm        DECIMAL(18,7),
  fx_rate           DECIMAL(12,6),
  stellar_tx_hash   TEXT,
  stellar_fee_xlm   DECIMAL(18,7),
  status            tx_status NOT NULL DEFAULT 'pending',
  notes             TEXT,
  location          TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tx_user_id     ON transactions (user_id);
CREATE INDEX IF NOT EXISTS idx_tx_created_at  ON transactions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tx_type        ON transactions (type);
CREATE INDEX IF NOT EXISTS idx_tx_status      ON transactions (status);
CREATE INDEX IF NOT EXISTS idx_tx_user_date   ON transactions (user_id, created_at DESC);
