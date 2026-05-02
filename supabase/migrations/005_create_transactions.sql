-- ============================================
-- Migration 005: Transactions Table
-- Unified ledger for all financial activity
-- ============================================

-- Transaction types
CREATE TYPE tx_type AS ENUM (
  'qr_payment',          -- QR-based merchant payment
  'fd_interest',         -- Interest payout from FD
  'credit_limit_change', -- System-initiated limit adjustment
  'fd_creation'          -- FD lock event
);

-- Transaction status
CREATE TYPE tx_status AS ENUM ('pending', 'cleared', 'failed');

CREATE TABLE IF NOT EXISTS transactions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type              tx_type NOT NULL,
  merchant_name     TEXT,                              -- NULL for system events
  merchant_category TEXT,                              -- 'Dining', 'Grocery', etc.
  amount_usd        DECIMAL(18,2),
  amount_local      DECIMAL(18,2),                     -- amount in local currency (INR)
  local_currency    TEXT NOT NULL DEFAULT 'INR',
  amount_xlm        DECIMAL(18,7),
  fx_rate           DECIMAL(12,6),                     -- USD to local currency rate
  stellar_tx_hash   TEXT,                              -- Stellar ledger hash
  stellar_fee_xlm   DECIMAL(18,7),
  status            tx_status NOT NULL DEFAULT 'pending',
  notes             TEXT,                              -- user-added tags/notes
  location          TEXT,                              -- "Bandra West, Mumbai"
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Primary query patterns
CREATE INDEX idx_tx_user_id     ON transactions (user_id);
CREATE INDEX idx_tx_created_at  ON transactions (created_at DESC);
CREATE INDEX idx_tx_type        ON transactions (type);
CREATE INDEX idx_tx_status      ON transactions (status);

-- Composite index for filtered + sorted queries (History screen)
CREATE INDEX idx_tx_user_date   ON transactions (user_id, created_at DESC);
