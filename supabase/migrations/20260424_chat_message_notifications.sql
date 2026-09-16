-- Migration: Chat Message Push Notifications Trigger
-- Date: 2026-04-24
-- Purpose: Automatically sends push notifications via Edge Function when a client or driver sends a message in chat.

CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION public.fn_notify_chat_message()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
    target_id UUID;
    target_type TEXT;
    sender_name TEXT;
    notification_title TEXT;
    notification_body TEXT;
    order_rec RECORD;
    edge_function_url TEXT := 'https://fsxiioldnxdzidcunmma.supabase.co/functions/v1/send-notification';
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';
BEGIN
    -- Determine target and sender details
    -- 1. Check if sender is a customer user in profiles
    SELECT full_name INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;

    IF sender_name IS NOT NULL THEN
        -- Sender is customer → Target recipient is DRIVER
        target_type := 'driver';
        target_id := NEW.receiver_id;
        
        -- Fallback: If receiver_id was not explicitly specified, lookup driver_id from orders table
        IF target_id IS NULL AND NEW.order_id IS NOT NULL THEN
            SELECT driver_id INTO target_id FROM public.orders WHERE id = NEW.order_id;
        END IF;

        notification_title := COALESCE(sender_name, 'Customer');
    ELSE
        -- 2. Check if sender is a driver
        SELECT full_name INTO sender_name FROM public.drivers WHERE id = NEW.sender_id;
        
        IF sender_name IS NOT NULL THEN
            -- Sender is driver → Target recipient is CUSTOMER USER
            target_type := 'user';
            target_id := NEW.receiver_id;

            -- Fallback: If receiver_id was not explicitly specified, lookup user_id from orders table
            IF target_id IS NULL AND NEW.order_id IS NOT NULL THEN
                SELECT user_id INTO target_id FROM public.orders WHERE id = NEW.order_id;
            END IF;

            notification_title := COALESCE(sender_name, 'Driver');
        ELSE
            -- Unknown sender type — fallback lookup from orders
            IF NEW.order_id IS NOT NULL THEN
                SELECT user_id, driver_id INTO order_rec FROM public.orders WHERE id = NEW.order_id;
                IF NEW.sender_id = order_rec.user_id THEN
                    target_type := 'driver';
                    target_id := order_rec.driver_id;
                    notification_title := 'Customer';
                ELSE
                    target_type := 'user';
                    target_id := order_rec.user_id;
                    notification_title := 'Driver';
                END IF;
            END IF;
        END IF;
    END IF;

    -- Body preview (limit to 120 chars)
    notification_body := NEW.message;
    IF length(notification_body) > 120 THEN
        notification_body := substring(notification_body from 1 for 117) || '...';
    END IF;

    -- If we identified target recipient, call Edge Function
    IF target_id IS NOT NULL AND target_type IS NOT NULL AND target_id <> NEW.sender_id THEN
        payload := jsonb_build_object(
            'target_type', target_type,
            'target_id', target_id,
            'title', notification_title,
            'body', notification_body,
            'data', jsonb_build_object(
                'type', 'chat',
                'order_id', NEW.order_id,
                'sender_id', NEW.sender_id,
                'sender_name', COALESCE(sender_name, notification_title),
                'receiver_id', target_id
            )
        );

        PERFORM net.http_post(
            url := edge_function_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || anon_key
            ),
            body := payload
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on public.messages
DROP TRIGGER IF EXISTS tr_chat_message_notification ON public.messages;
CREATE TRIGGER tr_chat_message_notification
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_notify_chat_message();

-- Reload schema
NOTIFY pgrst, 'reload schema';
