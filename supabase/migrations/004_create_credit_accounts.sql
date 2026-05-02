-- ============================================
-- Migration 004: Credit Accounts Table
-- Derived credit line backed by FDs
-- ============================================

CREATE TABLE IF NOT EXISTS credit_accounts (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  total_credit_limit  DECIMAL(18,2) NOT NULL DEFAULT 0.00,   -- sum of all active FD principals
  used_balance        DECIMAL(18,2) NOT NULL DEFAULT 0.00,   -- total spent via credit
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Fast lookup by user
CREATE INDEX idx_credit_user_id ON credit_accounts (user_id);

-- Business constraints
ALTER TABLE credit_accounts
  ADD CONSTRAINT chk_credit_limit     CHECK (total_credit_limit >= 0),
  ADD CONSTRAINT chk_credit_used      CHECK (used_balance >= 0),
  ADD CONSTRAINT chk_credit_not_over  CHECK (used_balance <= total_credit_limit);

CREATE TRIGGER trg_credit_updated_at
  BEFORE UPDATE ON credit_accounts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
