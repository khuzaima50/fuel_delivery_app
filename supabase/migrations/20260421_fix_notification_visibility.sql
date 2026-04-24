-- Migration: Fix Notification Visibility and RLS
-- Date: 2026-04-21

-- 1. Ensure RLS is correctly configured for local insertions from the app
-- Drop existing policies first to avoid conflicts
DROP POLICY IF EXISTS "Drivers can insert their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Drivers can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Drivers can update their own notifications" ON public.notifications;

-- Create robust policies
CREATE POLICY "Drivers can insert their own notifications" ON public.notifications
    FOR INSERT WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "Drivers can view their own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "Drivers can update their own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = driver_id)
    WITH CHECK (auth.uid() = driver_id);

-- 2. Update the notification trigger function to be more comprehensive
-- This ensures that even if app-side insertion fails, the DB will record it.
CREATE OR REPLACE FUNCTION public.fn_notify_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
    payload JSONB;
    target_id UUID;
    target_type TEXT;
    notification_title TEXT;
    notification_body TEXT;
    edge_function_url TEXT := 'https://fsxiioldnxdzidcunmma.supabase.co/functions/v1/send-notification';
    anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzeGlpb2xkbnhkemlkY3VubW1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4NTcxNTMsImV4cCI6MjA4OTQzMzE1M30.6oI2QCnP4uPdCRF989oOPFsZXyPPr7wkEFioK3lQ1wA';
BEGIN
    -- Only trigger on certain status changes or new inserts
    IF (OLD.status IS DISTINCT FROM NEW.status) OR (TG_OP = 'INSERT') THEN
        
        -- Logic for pushing notifications via Edge Function
        target_id := NULL;
        target_type := NULL;
        
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
                -- Skip Edge Function if no match
        END CASE;

        -- Trigger Edge Function Notification
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

            PERFORM net.http_post(
                url := edge_function_url,
                headers := jsonb_build_object(
                    'Content-Type', 'application/json',
                    'Authorization', 'Bearer ' || anon_key
                ),
                body := payload
            );
        END IF;

        -- ── DRIVER HISTORY LOGGING ──
        -- Ensure the driver ALWAYS gets a notification entry for their own actions in history
        IF NEW.driver_id IS NOT NULL THEN
            DECLARE
                driver_history_title TEXT;
                driver_history_body TEXT;
            BEGIN
                CASE LOWER(NEW.status::text)
                    WHEN 'accepted' THEN
                        driver_history_title := 'Order Accepted ✓';
                        driver_history_body := 'Order #' || UPPER(substring(NEW.id::text, 1, 4)) || ' is now in your active queue.';
                    WHEN 'driver_arrived' THEN
                        driver_history_title := 'Arrival Logged 📍';
                        driver_history_body := 'You reached the customer location for order #' || UPPER(substring(NEW.id::text, 1, 4));
                    WHEN 'in_progress' THEN
                        driver_history_title := 'Fueling Started 🚛';
                        driver_history_body := 'Pumping fuel for customer.';
                    WHEN 'completed' THEN
                        driver_history_title := 'Delivery Finalized ✅';
                        driver_history_body := 'Order #' || UPPER(substring(NEW.id::text, 1, 4)) || ' has been closed.';
                    ELSE 
                        driver_history_title := NULL;
                END CASE;

                IF driver_history_title IS NOT NULL THEN
                    INSERT INTO public.notifications (driver_id, order_id, title, message, body, type)
                    VALUES (NEW.driver_id, NEW.id, driver_history_title, driver_history_body, driver_history_body, 'order');
                END IF;
            EXCEPTION WHEN OTHERS THEN
                -- Don't crash the main trigger if history logging fails
                RAISE WARNING 'Failed to log driver notification history: %', SQLERRM;
            END;
        END IF;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Reload schema
NOTIFY pgrst, 'reload schema';
