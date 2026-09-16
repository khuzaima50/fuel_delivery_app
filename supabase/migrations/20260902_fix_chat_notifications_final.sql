-- =============================================================================
-- Migration: 20260902_fix_chat_notifications_final.sql
-- Purpose: Complete & reliable Chat Notification Trigger for Customer <-> Driver
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/fsxiioldnxdzidcunmma/sql
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net;

-- 1. Ensure fcm_token exists on both profiles and drivers tables
ALTER TABLE public.drivers ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
CREATE INDEX IF NOT EXISTS idx_drivers_fcm_token ON public.drivers(fcm_token) WHERE fcm_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON public.profiles(fcm_token) WHERE fcm_token IS NOT NULL;

-- 2. Fixed trigger function for chat messages
CREATE OR REPLACE FUNCTION public.fn_notify_chat_message()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
    target_id UUID;
    target_type TEXT;
    sender_name TEXT;
    notification_title TEXT;
    notification_body TEXT;
    sender_role TEXT;
    edge_function_url TEXT := 'https://fsxiioldnxdzidcunmma.supabase.co/functions/v1/send-notification';
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';
BEGIN
    -- Look up sender role and full_name in profiles
    SELECT role, full_name INTO sender_role, sender_name 
    FROM public.profiles 
    WHERE id::text = NEW.sender_id::text;

    -- If sender is a driver (checked in profiles or drivers table):
    IF sender_role = 'driver' OR EXISTS (SELECT 1 FROM public.drivers WHERE id::text = NEW.sender_id::text) THEN
        -- Sender is Driver -> notify Customer (user)
        target_type := 'user';
        target_id := NEW.receiver_id;
        IF target_id IS NULL AND NEW.order_id IS NOT NULL THEN
            SELECT user_id INTO target_id FROM public.orders WHERE id::text = NEW.order_id::text;
        END IF;
        notification_title := COALESCE(sender_name, 'Driver');
    ELSE
        -- Sender is Customer -> notify Driver
        target_type := 'driver';
        target_id := NEW.receiver_id;
        IF target_id IS NULL AND NEW.order_id IS NOT NULL THEN
            SELECT driver_id INTO target_id FROM public.orders WHERE id::text = NEW.order_id::text;
        END IF;
        notification_title := COALESCE(sender_name, 'Customer');
    END IF;

    -- If target recipient is missing or sender is receiver, skip
    IF target_id IS NULL OR target_id::text = NEW.sender_id::text THEN
        RETURN NEW;
    END IF;

    -- Build message preview (max 120 chars)
    notification_body := NEW.message;
    IF length(notification_body) > 120 THEN
        notification_body := substring(notification_body from 1 for 117) || '...';
    END IF;

    -- Build payload for send-notification Edge Function
    payload := jsonb_build_object(
        'target_type', target_type,
        'target_id',   target_id,
        'title',       notification_title,
        'body',        notification_body,
        'data', jsonb_build_object(
            'type',        'chat',
            'order_id',    NEW.order_id,
            'sender_id',   NEW.sender_id,
            'sender_name', notification_title,
            'receiver_id', target_id
        )
    );

    -- Call Edge Function via pg_net
    PERFORM net.http_post(
        url     := edge_function_url,
        headers := jsonb_build_object(
            'Content-Type',  'application/json',
            'Authorization', 'Bearer ' || anon_key
        ),
        body    := payload
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Re-create trigger on public.messages
DROP TRIGGER IF EXISTS tr_chat_message_notification ON public.messages;
CREATE TRIGGER tr_chat_message_notification
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_notify_chat_message();

-- 4. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
