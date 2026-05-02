-- ============================================
-- Migration 006: Add base_currency to wallets
-- User's default currency for payment conversion
-- ============================================

ALTER TABLE wallets
  ADD COLUMN IF NOT EXISTS base_currency TEXT NOT NULL DEFAULT 'USD';
