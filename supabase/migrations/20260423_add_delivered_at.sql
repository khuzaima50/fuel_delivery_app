-- 20260423_add_delivered_at.sql
-- Adds the delivered_at timestamp column to the orders table.
-- This column is set when a driver completes an order and is used by the
-- Delivered tab to show only orders from the last 24 hours.

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS delivered_at TIMESTAMPTZ;

-- Back-fill: for any orders already marked delivered/completed that have
-- completed_at but no delivered_at, copy the value over so the 24-hour
-- filter still works for existing data.
UPDATE public.orders
SET delivered_at = completed_at
WHERE delivered_at IS NULL
  AND completed_at IS NOT NULL
  AND status IN ('delivered', 'completed');

-- Index for fast 24-hour range queries on the Delivered tab
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at ON public.orders(delivered_at);

-- Refresh PostgREST schema cache so the new column is immediately usable
NOTIFY pgrst, 'reload schema';
