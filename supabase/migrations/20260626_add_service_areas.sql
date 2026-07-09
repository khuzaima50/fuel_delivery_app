-- Migration: Add Service Areas Table
-- Description: Creates the service_areas table for circular global service area configurations

CREATE TABLE IF NOT EXISTS public.service_areas (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  center_lat  DOUBLE PRECISION NOT NULL,
  center_lng  DOUBLE PRECISION NOT NULL,
  radius_km   DOUBLE PRECISION NOT NULL DEFAULT 25.0,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.service_areas ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Authenticated users can view service areas
DROP POLICY IF EXISTS "service_areas_select_all" ON public.service_areas;
CREATE POLICY "service_areas_select_all" ON public.service_areas
    FOR SELECT USING (auth.role() = 'authenticated');

-- Notify postgrest to reload the schema cache
NOTIFY pgrst, 'reload schema';
