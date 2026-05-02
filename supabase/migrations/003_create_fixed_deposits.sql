-- ============================================
-- Migration 003: Fixed Deposits Table
-- FDs that back the user's credit line
-- ============================================

-- Enum-like type for FD status
CREATE TYPE fd_status AS ENUM ('active', 'matured', 'withdrawn');

-- Enum-like type for currency
CREATE TYPE fd_currency AS ENUM ('USD', 'XLM');

CREATE TABLE IF NOT EXISTS fixed_deposits (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name              TEXT NOT NULL,                      -- e.g. "Stellar Vault Alpha"
  account_number    TEXT NOT NULL DEFAULT substring(gen_random_uuid()::text, 1, 4),  -- last 4 digits display
  principal_amount  DECIMAL(18,2) NOT NULL,
  currency          fd_currency NOT NULL DEFAULT 'USD',
  apy_rate          DECIMAL(5,2) NOT NULL,              -- e.g. 5.25
  tenor_months      INT NOT NULL,                       -- 3, 6, or 12
  start_date        DATE NOT NULL DEFAULT CURRENT_DATE,
  maturity_date     DATE NOT NULL,
  estimated_interest DECIMAL(18,2) NOT NULL DEFAULT 0.00,
  status            fd_status NOT NULL DEFAULT 'active',
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- List all FDs for a user, filter by status
CREATE INDEX idx_fd_user_id ON fixed_deposits (user_id);
CREATE INDEX idx_fd_status  ON fixed_deposits (status);

-- Validate tenor is one of the allowed values
ALTER TABLE fixed_deposits
  ADD CONSTRAINT chk_fd_tenor CHECK (tenor_months IN (3, 6, 12)),
  ADD CONSTRAINT chk_fd_principal CHECK (principal_amount > 0),
  ADD CONSTRAINT chk_fd_apy CHECK (apy_rate > 0 AND apy_rate < 100);

CREATE TRIGGER trg_fd_updated_at
  BEFORE UPDATE ON fixed_deposits
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
