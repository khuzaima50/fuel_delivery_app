-- Migration: Create notifications table and RLS policies
-- Date: 2026-04-20

-- 1. Create the notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
    order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    message TEXT, -- Used by Flutter app
    body TEXT,    -- Used by Edge Function / Backup
    type TEXT DEFAULT 'system', -- 'order', 'chat', 'system', 'alert'
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure at least one recipient is specified
    CONSTRAINT recipient_check CHECK (user_id IS NOT NULL OR driver_id IS NOT NULL)
);

-- 2. Enable Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS Policies
-- Users can see their own notifications
CREATE POLICY "Users can view their own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Drivers can see their own notifications
CREATE POLICY "Drivers can view their own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can update their own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = driver_id)
    WITH CHECK (auth.uid() = driver_id);

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_driver_id ON public.notifications(driver_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
