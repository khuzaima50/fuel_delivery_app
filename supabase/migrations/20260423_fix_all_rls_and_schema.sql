-- =============================================================================
-- 20260423_fix_all_rls_and_schema.sql
-- COMPLETE DATA SAVING FIX — Run this entire script in Supabase SQL Editor
-- Fixes: RLS policies, schema gaps, trigger hardening, driver row creation
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 1: ENSURE ALL REQUIRED COLUMNS EXIST
-- (safe to re-run — all use IF NOT EXISTS / DO $$ ... EXCEPTION)
-- ─────────────────────────────────────────────────────────────────────────────

-- drivers table: extra columns used by the app
DO $$ BEGIN ALTER TABLE public.drivers ADD COLUMN documents_submitted BOOLEAN DEFAULT FALSE; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.drivers ADD COLUMN is_profile_completed BOOLEAN DEFAULT FALSE; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.drivers ADD COLUMN avatar_url TEXT; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.drivers ADD COLUMN fcm_token TEXT; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.drivers ADD COLUMN vehicle_type TEXT; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.drivers ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); EXCEPTION WHEN duplicate_column THEN null; END $$;

-- orders table: all timestamp + amount columns used by the app
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN accepted_at TIMESTAMPTZ; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN arrived_at TIMESTAMPTZ; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN completed_at TIMESTAMPTZ; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN delivered_at TIMESTAMPTZ; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN assigned_at TIMESTAMPTZ; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN fuel_quantity NUMERIC; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN fuel_quantity_gallons NUMERIC; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN total_amount NUMERIC(10,2) DEFAULT 0; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN driver_earning NUMERIC(10,2) DEFAULT 0; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN meter_reading_start NUMERIC; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN meter_reading_end NUMERIC; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN pickup_photo_url TEXT; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN delivery_photo_url TEXT; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN is_emergency BOOLEAN DEFAULT FALSE; EXCEPTION WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); EXCEPTION WHEN duplicate_column THEN null; END $$;

-- driver_vehicles table
DO $$ BEGIN ALTER TABLE public.driver_vehicles ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW(); EXCEPTION WHEN duplicate_column THEN null; END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 2: ADD 'available' TO order_status ENUM
-- The app uses 'available' but the original schema only had 'pending'.
-- The available orders tab filters on 'available' | 'pending'.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$ BEGIN ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'available'; EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'emergency'; EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'on_the_way'; EXCEPTION WHEN duplicate_object THEN null; END $$;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 3: DROP ALL EXISTING BROKEN RLS POLICIES & RECREATE CORRECTLY
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 3a. DRIVERS TABLE ────────────────────────────────────────────────────────
-- Problem: No INSERT policy exists. The trigger inserts as SECURITY DEFINER
-- so the trigger itself is fine, but the app's update/read calls need RLS.
-- The profile_setup_screen does an UPDATE, vehicle_info_screen does an UPDATE.
-- Those are auth.uid() = id calls, which the existing policy covers.
-- However if the trigger fails silently (e.g. due to duplicate), the app's
-- subsequent UPDATEs find no row → also fail silently.
-- Fix: add an explicit INSERT policy so the app can also insert as a fallback.

ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profile view" ON public.drivers;
DROP POLICY IF EXISTS "Drivers can manage their own profile" ON public.drivers;
DROP POLICY IF EXISTS "drivers_select_all" ON public.drivers;
DROP POLICY IF EXISTS "drivers_insert_own" ON public.drivers;
DROP POLICY IF EXISTS "drivers_update_own" ON public.drivers;

-- Any authenticated user can read any driver profile (needed for order display)
CREATE POLICY "drivers_select_all" ON public.drivers
    FOR SELECT USING (auth.role() = 'authenticated');

-- A driver can INSERT their own row (auth.uid() must match id)
-- This is needed as a fallback if the trigger fails
CREATE POLICY "drivers_insert_own" ON public.drivers
    FOR INSERT WITH CHECK (auth.uid() = id);

-- A driver can UPDATE their own row
CREATE POLICY "drivers_update_own" ON public.drivers
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);


-- ── 3b. DRIVER_VEHICLES TABLE ─────────────────────────────────────────────────
ALTER TABLE public.driver_vehicles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Drivers can manage their own vehicles" ON public.driver_vehicles;
DROP POLICY IF EXISTS "Everyone can view vehicle info" ON public.driver_vehicles;
DROP POLICY IF EXISTS "vehicles_select_all" ON public.driver_vehicles;
DROP POLICY IF EXISTS "vehicles_insert_own" ON public.driver_vehicles;
DROP POLICY IF EXISTS "vehicles_update_own" ON public.driver_vehicles;
DROP POLICY IF EXISTS "vehicles_delete_own" ON public.driver_vehicles;

CREATE POLICY "vehicles_select_all" ON public.driver_vehicles
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "vehicles_insert_own" ON public.driver_vehicles
    FOR INSERT WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "vehicles_update_own" ON public.driver_vehicles
    FOR UPDATE USING (auth.uid() = driver_id)
    WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "vehicles_delete_own" ON public.driver_vehicles
    FOR DELETE USING (auth.uid() = driver_id);


-- ── 3c. ORDERS TABLE ──────────────────────────────────────────────────────────
-- Problem: The existing SELECT policy only allows drivers to see orders where
-- auth.uid() = driver_id OR status = 'pending'. But 'available' orders have
-- driver_id = NULL and status = 'available' — so they are invisible!
-- Also: there is NO INSERT policy, so the app can never create orders.
-- The UPDATE policy requires auth.uid() = driver_id, but when accepting an
-- unassigned order driver_id is null → UPDATE fails silently!

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Drivers can view available or assigned orders" ON public.orders;
DROP POLICY IF EXISTS "Drivers can update assigned orders" ON public.orders;
DROP POLICY IF EXISTS "orders_select" ON public.orders;
DROP POLICY IF EXISTS "orders_insert" ON public.orders;
DROP POLICY IF EXISTS "orders_update_assigned" ON public.orders;
DROP POLICY IF EXISTS "orders_update_available" ON public.orders;

-- SELECT: authenticated drivers can see all orders
-- (available ones have driver_id NULL, assigned ones have their own driver_id)
CREATE POLICY "orders_select" ON public.orders
    FOR SELECT USING (auth.role() = 'authenticated');

-- INSERT: authenticated drivers can create orders (needed if app creates orders)
CREATE POLICY "orders_insert" ON public.orders
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- UPDATE for accepting an unassigned order (driver_id IS NULL at time of accept)
CREATE POLICY "orders_update_available" ON public.orders
    FOR UPDATE
    USING (
        auth.role() = 'authenticated'
        AND (driver_id IS NULL OR driver_id = auth.uid())
    )
    WITH CHECK (
        auth.role() = 'authenticated'
        AND (driver_id IS NULL OR driver_id = auth.uid())
    );


-- ── 3d. PROFILES TABLE ───────────────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Drivers can view customer profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can manage their own profile" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_authenticated" ON public.profiles;
DROP POLICY IF EXISTS "profiles_all_own" ON public.profiles;

-- Drivers must be able to read customer profiles (shown in order details)
CREATE POLICY "profiles_select_authenticated" ON public.profiles
    FOR SELECT USING (auth.role() = 'authenticated');

-- Users manage their own profile
CREATE POLICY "profiles_all_own" ON public.profiles
    FOR ALL USING (auth.uid() = id);


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 4: HARDEN THE DRIVER-CREATION TRIGGER
-- Use ON CONFLICT DO UPDATE so if the row already exists it is updated,
-- not silently skipped. This prevents the "update finds 0 rows" problem.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.handle_new_driver()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.drivers (id, full_name, email, phone, status, created_at, updated_at)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'New Driver'),
    new.email,
    COALESCE(new.raw_user_meta_data->>'phone', ''),
    'offline',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email       = EXCLUDED.email,
    updated_at  = NOW();
  RETURN new;
EXCEPTION WHEN OTHERS THEN
  -- Log but never block auth signup
  RAISE WARNING 'handle_new_driver failed for %: %', new.id, SQLERRM;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_driver();


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 5: BACK-FILL — create driver rows for any users who have none
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO public.drivers (id, full_name, email, phone, status, created_at, updated_at)
SELECT
    u.id,
    COALESCE(u.raw_user_meta_data->>'full_name', 'Driver'),
    u.email,
    COALESCE(u.raw_user_meta_data->>'phone', ''),
    'offline',
    NOW(),
    NOW()
FROM auth.users u
WHERE u.id NOT IN (SELECT id FROM public.drivers)
ON CONFLICT (id) DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 6: FIX THE LOCK-COMPLETED-ORDERS TRIGGER
-- The current trigger blocks updates where OLD.status = 'completed' OR
-- OLD.status = 'delivered'. But it also fires when we write delivered_at
-- to an already-delivered row (e.g. a retry). Make it ONLY block status
-- changes, not all updates.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.fn_lock_completed_orders()
RETURNS TRIGGER AS $$
BEGIN
    -- Only block if the status itself is being changed away from a final state
    IF (OLD.status IN ('completed', 'delivered'))
       AND (NEW.status IS DISTINCT FROM OLD.status) THEN
        RAISE EXCEPTION
            'Order % is already % and cannot be changed to %.',
            OLD.id, OLD.status, NEW.status;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trig_lock_completed_orders ON public.orders;
CREATE TRIGGER trig_lock_completed_orders
BEFORE UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.fn_lock_completed_orders();


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 7: STORAGE BUCKET POLICIES (run if needed)
-- If bucket policies are missing, uncomment and run in Supabase Storage tab
-- OR use the SQL below (requires pg_policies on storage.objects).
-- ─────────────────────────────────────────────────────────────────────────────

-- Allow authenticated users to upload to driver_documents bucket
DO $$
BEGIN
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('driver_documents', 'driver_documents', false)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO storage.buckets (id, name, public)
  VALUES ('avatars', 'avatars', true)
  ON CONFLICT (id) DO NOTHING;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Bucket creation skipped: %', SQLERRM;
END $$;

-- Storage RLS (safe recreate)
DROP POLICY IF EXISTS "Authenticated upload to driver_documents" ON storage.objects;
CREATE POLICY "Authenticated upload to driver_documents" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'driver_documents'
        AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Owner can read driver_documents" ON storage.objects;
CREATE POLICY "Owner can read driver_documents" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'driver_documents'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

DROP POLICY IF EXISTS "Authenticated upload to avatars" ON storage.objects;
CREATE POLICY "Authenticated upload to avatars" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Public read avatars" ON storage.objects;
CREATE POLICY "Public read avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Owner update avatars" ON storage.objects;
CREATE POLICY "Owner update avatars" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'avatars'
        AND auth.role() = 'authenticated'
    );


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 8: PERFORMANCE INDEXES
-- ─────────────────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_orders_status        ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_driver_id     ON public.orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_delivered_at  ON public.orders(delivered_at);
CREATE INDEX IF NOT EXISTS idx_orders_created_at    ON public.orders(created_at DESC);

-- Unique index required for driver_vehicles upsert ON CONFLICT (driver_id, license_plate)
CREATE UNIQUE INDEX IF NOT EXISTS idx_driver_vehicles_driver_plate
    ON public.driver_vehicles(driver_id, license_plate);


-- ─────────────────────────────────────────────────────────────────────────────
-- SECTION 9: REFRESH POSTGREST SCHEMA CACHE
-- ─────────────────────────────────────────────────────────────────────────────

NOTIFY pgrst, 'reload schema';

-- Done! Run the verification queries below to confirm everything is working.

-- ─────────────────────────────────────────────────────────────────────────────
-- VERIFICATION QUERIES (run each one separately to confirm)
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Check driver rows exist for all auth users:
-- SELECT u.email, d.id IS NOT NULL AS has_driver_row, d.full_name
-- FROM auth.users u LEFT JOIN public.drivers d ON d.id = u.id;

-- 2. Check RLS policies on orders:
-- SELECT policyname, cmd, qual, with_check FROM pg_policies WHERE tablename = 'orders';

-- 3. Check RLS policies on drivers:
-- SELECT policyname, cmd, qual, with_check FROM pg_policies WHERE tablename = 'drivers';

-- 4. Check order_status enum values:
-- SELECT unnest(enum_range(NULL::order_status))::text AS status_values;

-- 5. Check orders columns:
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_name = 'orders' ORDER BY ordinal_position;
