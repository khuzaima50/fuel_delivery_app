-- Migration: Notification Triggers for Order Updates
-- Date: 2026-04-20

-- 1. Enable the required extensions
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Create the notification function
CREATE OR REPLACE FUNCTION public.fn_notify_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
    target_id UUID;
    target_type TEXT;
    notification_title TEXT;
    notification_body TEXT;
    edge_function_url TEXT := 'https://fsxiioldnxdzidcunmma.supabase.co/functions/v1/send-notification';
    -- Using the project's Anon Key for authorization. 
    -- This allows the trigger to call the Edge Function securely.
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';
BEGIN
    -- Only trigger on certain status changes or new inserts
    IF (OLD.status IS DISTINCT FROM NEW.status) OR (TG_OP = 'INSERT') THEN
        
        -- Default values
        target_id := NULL;
        target_type := NULL;
        
        -- Logic for different statuses (case-insensitive)
        CASE LOWER(NEW.status::text)
            WHEN 'assigned' THEN
                target_id := NEW.driver_id;
                target_type := 'driver';
                notification_title := 'New Order Assigned 🚛';
                notification_body := 'You have been assigned a new fuel delivery order.';
                
            WHEN 'accepted' THEN
                target_id := NEW.user_id;
                target_type := 'user';
                notification_title := 'Driver Accepted 🚗';
                notification_body := 'A driver has accepted your order and is on the way!';
                
            WHEN 'driver_arrived' THEN
                target_id := NEW.user_id;
                target_type := 'user';
                notification_title := 'Driver Arrived 📍';
                notification_body := 'Your driver has arrived at your location.';
                
            WHEN 'in_progress' THEN
                target_id := NEW.user_id;
                target_type := 'user';
                notification_title := 'Delivery Started 🚛';
                notification_body := 'Your fuel delivery is now being pumped!';
                
            WHEN 'delivered' THEN
                target_id := NEW.user_id;
                target_type := 'user';
                notification_title := 'Fuel Delivered ✅';
                notification_body := 'Your fuel has been delivered successfully. Please confirm!';
            WHEN 'completed' THEN
                target_id := NEW.user_id;
                target_type := 'user';
                notification_title := 'Order Completed ✅';
                notification_body := 'Your fuel delivery has been completed. Thank you!';
                
            ELSE
                -- No notification for other statuses (e.g. pending, cancelled)
                RETURN NEW;
        END CASE;

        -- If we have a recipient, call the edge function
        IF target_id IS NOT NULL AND target_type IS NOT NULL THEN
            payload := jsonb_build_object(
                'target_type', target_type,
                'target_id', target_id,
                'title', notification_title,
                'body', notification_body,
                'data', jsonb_build_object(
                    'type', 'order_update',
                    'order_id', NEW.id,
                    'status', NEW.status
                )
            );

            -- Use pg_net to call the Edge Function asynchronously
            -- Use pg_net to call the Edge Function asynchronously
            PERFORM net.http_post(
                url := edge_function_url,
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || anon_key
                ),
                body := payload
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the trigger on orders table
DROP TRIGGER IF EXISTS tr_order_status_notification ON public.orders;
CREATE TRIGGER tr_order_status_notification
    AFTER INSERT OR UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_notify_order_status_change();
