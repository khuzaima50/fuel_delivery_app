-- Migration: Standardize Order Statuses to UPPERCASE
-- Date: 2026-04-20

-- 1. Create a temporary text column to store normalized statuses
ALTER TABLE public.orders ADD COLUMN temp_status TEXT;

-- 2. Populate temp_status with uppercase versions of current statuses
UPDATE public.orders SET temp_status = UPPER(status::text);

-- 3. In case the order_status ENUM needs to support Uppercase specifically,
-- but since it's an ENUM we might need to redefine it or check existing values.
-- Based on project requirements, we want to ensure visibility in the app.

-- Update existing records to uppercase
-- This assumes the ENUM itself is case-sensitive and might need adjustment.
-- If the ENUM already has lowercase values, we can't just set them to uppercase 
-- without adding the uppercase values to the ENUM type first.

DO $$ 
BEGIN
    ALTER TYPE order_status ADD VALUE 'PENDING';
    EXCEPTION WHEN duplicate_object THEN null;
END $$;
DO $$ 
BEGIN
    ALTER TYPE order_status ADD VALUE 'ASSIGNED';
    EXCEPTION WHEN duplicate_object THEN null;
END $$;
DO $$ 
BEGIN
    ALTER TYPE order_status ADD VALUE 'ACCEPTED';
    EXCEPTION WHEN duplicate_object THEN null;
END $$;
DO $$ 
BEGIN
    ALTER TYPE order_status ADD VALUE 'DRIVER_ARRIVED';
    EXCEPTION WHEN duplicate_object THEN null;
END $$;
DO $$ 
BEGIN
    ALTER TYPE order_status ADD VALUE 'IN_PROGRESS';
    EXCEPTION WHEN duplicate_object THEN null;
END $$;
DO $$ 
BEGIN
    ALTER TYPE order_status ADD VALUE 'DELIVERED';
    EXCEPTION WHEN duplicate_object THEN null;
END $$;
DO $$ 
BEGIN
    ALTER TYPE order_status ADD VALUE 'COMPLETED';
    EXCEPTION WHEN duplicate_object THEN null;
END $$;
DO $$ 
BEGIN
    ALTER TYPE order_status ADD VALUE 'CANCELLED';
    EXCEPTION WHEN duplicate_object THEN null;
END $$;
DO $$ 
BEGIN
    ALTER TYPE order_status ADD VALUE 'SCHEDULED';
    EXCEPTION WHEN duplicate_object THEN null;
END $$;

-- 4. Now perform the update for all orders
UPDATE public.orders SET status = UPPER(status::text)::order_status;

-- 5. Clean up
ALTER TABLE public.orders DROP COLUMN temp_status;

-- 6. Refresh schema cache
NOTIFY pgrst, 'reload schema';
