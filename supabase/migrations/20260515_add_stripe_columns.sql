-- Migration: Add Stripe Account Info to Drivers
-- Date: 2026-05-15

-- Add columns to store Stripe Connect account info
ALTER TABLE public.drivers 
ADD COLUMN IF NOT EXISTS stripe_account_id TEXT,
ADD COLUMN IF NOT EXISTS stripe_onboarding_completed BOOLEAN DEFAULT FALSE;

-- Refresh PostgREST cache
NOTIFY pgrst, 'reload schema';
