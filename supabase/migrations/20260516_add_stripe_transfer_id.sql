-- Migration: Add stripe_transfer_id to wallet_transactions
-- Date: 2026-05-16

ALTER TABLE public.wallet_transactions 
ADD COLUMN IF NOT EXISTS stripe_transfer_id TEXT;

-- Refresh PostgREST cache
NOTIFY pgrst, 'reload schema';
