-- Migration: Final Notification Repair & Dynamic Test Data (VERIFIED)
-- Date: 2026-04-20

-- 1. Ensure fcm_token columns exist
DO $$ 
BEGIN
    ALTER TABLE public.drivers ADD COLUMN fcm_token TEXT;
EXCEPTION WHEN duplicate_column THEN null;
END $$;

DO $$ 
BEGIN
    ALTER TABLE public.profiles ADD COLUMN fcm_token TEXT;
EXCEPTION WHEN duplicate_column THEN null;
END $$;

-- 2. Fix RLS for notifications table (Add INSERT policies)
DROP POLICY IF EXISTS "Drivers can insert their own notifications" ON public.notifications;
CREATE POLICY "Drivers can insert their own notifications" ON public.notifications
    FOR INSERT WITH CHECK (auth.uid() = driver_id);

DROP POLICY IF EXISTS "Users can insert their own notifications" ON public.notifications;
CREATE POLICY "Users can insert their own notifications" ON public.notifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. Create a Test Order for the LATEST ACTIVE driver (USING VERIFIED SCHEMA)
DO $$
DECLARE
    v_driver_id UUID;
    v_order_id UUID;
BEGIN
    -- Find the driver with a token who was updated most recently
    SELECT id INTO v_driver_id 
    FROM public.drivers 
    WHERE fcm_token IS NOT NULL 
    ORDER BY updated_at DESC 
    LIMIT 1;

    IF v_driver_id IS NOT NULL THEN
        -- Create a test order satisfying ALL verified constraints
        INSERT INTO public.orders (
            order_number, 
            user_id,
            fuel_type,
            quantity,
            total_price,
            status,
            payment_status,
            delivery_address
        ) VALUES (
            'ORD-' || floor(random() * 1000000)::text,
            v_driver_id, -- Using driver as user for test purposes
            'Petrol',    -- Verified Enum Value
            10.0,
            0.0,
            'scheduled', -- Verified status Value
            'PENDING',   -- Verified Payment Status Value
            'Verified Fix Street, Notification City'
        ) RETURNING id INTO v_order_id;

        -- Update it to 'ASSIGNED' to trigger the notification logic for the dynamic driver
        UPDATE public.orders 
        SET driver_id = v_driver_id,
            status = 'ASSIGNED'
        WHERE id = v_order_id;
        
        RAISE NOTICE 'Dynamic test order created and assigned to driver %: %', v_driver_id, v_order_id;
    ELSE
        RAISE NOTICE 'No drivers with FCM tokens found. Please log in first.';
    END IF;
END $$;

-- 4. Clean up discovery table
DROP TABLE IF EXISTS public.debug_schema;

-- 5. Refresh schema
NOTIFY pgrst, 'reload schema';
