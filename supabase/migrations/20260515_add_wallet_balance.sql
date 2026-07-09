-- Migration: Add Wallet Balance and Transactions
-- Date: 2026-05-15

-- 1. Add wallet_balance to drivers table
ALTER TABLE public.drivers 
ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(10, 2) DEFAULT 0.00;

-- 2. Create wallet_transactions table
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    type TEXT NOT NULL, -- 'earning', 'withdrawal', 'payout'
    status TEXT DEFAULT 'completed', -- 'pending', 'completed', 'failed'
    description TEXT,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable RLS on wallet_transactions
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for wallet_transactions
DROP POLICY IF EXISTS "Drivers can view their own transactions" ON public.wallet_transactions;
CREATE POLICY "Drivers can view their own transactions" 
ON public.wallet_transactions FOR SELECT 
USING (auth.uid() = driver_id);

-- 5. Refresh PostgREST cache
NOTIFY pgrst, 'reload schema';
