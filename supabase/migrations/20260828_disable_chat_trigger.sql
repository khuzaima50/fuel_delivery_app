-- Migration: Smart Chat Notification Trigger (Customer → Driver only)
-- Date: 2026-08-28
-- 
-- STRATEGY:
--   Driver → Customer: Flutter (NotificationService.notifyChatMessage) handles this directly.
--   Customer → Driver: DB trigger handles this (customer has separate app, no Flutter call possible).
--
-- This updated trigger ONLY fires when the sender is a CUSTOMER (found in profiles table).
-- When sender is a driver, we skip — Flutter already sent the notification.

CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION public.fn_notify_chat_message()
RETURNS TRIGGER AS $$
DECLARE
    sender_name TEXT;
    target_id UUID;
    notification_body TEXT;
    edge_function_url TEXT := 'https://fsxiioldnxdzidcunmma.supabase.co/functions/v1/send-notification';
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';
    payload JSONB;
BEGIN
    -- Only handle: sender is a CUSTOMER (found in profiles)
    -- Driver → Customer is already handled by Flutter (NotificationService.notifyChatMessage)
    SELECT full_name INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

    -- If sender is NOT in profiles → sender is driver → Flutter already notified customer → SKIP
    IF sender_name IS NULL THEN
        RETURN NEW;
    END IF;

    -- Sender IS a customer → notify driver
    target_id := NEW.receiver_id;

    -- Fallback: lookup driver_id from orders if receiver_id not set
    IF target_id IS NULL AND NEW.order_id IS NOT NULL THEN
        SELECT driver_id INTO target_id FROM public.orders WHERE id = NEW.order_id;
    END IF;

    -- If we still don't have a target, skip
    IF target_id IS NULL OR target_id = NEW.sender_id THEN
        RETURN NEW;
    END IF;

    -- Build message preview (max 120 chars)
    notification_body := NEW.message;
    IF length(notification_body) > 120 THEN
        notification_body := substring(notification_body from 1 for 117) || '...';
    END IF;

    -- Build payload
    payload := jsonb_build_object(
        'target_type', 'driver',
        'target_id',   target_id,
        'title',       COALESCE(sender_name, 'Customer'),
        'body',        notification_body,
        'data', jsonb_build_object(
            'type',        'chat',
            'order_id',    NEW.order_id,
            'sender_id',   NEW.sender_id,
            'sender_name', COALESCE(sender_name, 'Customer'),
            'receiver_id', target_id
        )
    );

    -- Call Edge Function asynchronously via pg_net
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

-- Re-create trigger
DROP TRIGGER IF EXISTS tr_chat_message_notification ON public.messages;
CREATE TRIGGER tr_chat_message_notification
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_notify_chat_message();

NOTIFY pgrst, 'reload schema';
