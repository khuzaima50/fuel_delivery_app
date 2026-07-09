-- Migration: Add Wallet Earning Trigger on Order Completion
-- Date: 2026-05-22

-- Create trigger function to update driver balance and insert wallet transaction
CREATE OR REPLACE FUNCTION public.fn_handle_driver_earning_on_order_completed()
RETURNS TRIGGER AS $$
DECLARE
    earning_amount NUMERIC(10, 2);
    driver_exists BOOLEAN;
BEGIN
    -- Check if status changed to completed (case-insensitive)
    IF (LOWER(NEW.status::text) = 'completed') AND (OLD.status IS DISTINCT FROM NEW.status OR OLD.status IS NULL) THEN
        
        -- Check if driver_id is present
        IF NEW.driver_id IS NULL THEN
            RETURN NEW;
        END IF;

        -- Check if driver exists in drivers table
        SELECT EXISTS(SELECT 1 FROM public.drivers WHERE id = NEW.driver_id) INTO driver_exists;
        IF NOT driver_exists THEN
            RETURN NEW;
        END IF;

        -- Determine the driver's earning amount
        earning_amount := COALESCE(NEW.driver_earning, 0.00);
        
        -- If driver_earning is 0 or null, calculate it as 10% of total_amount as fallback
        IF earning_amount = 0.00 THEN
            earning_amount := COALESCE(NEW.total_amount, 0.00) * 0.10;
        END IF;

        -- Ensure we have a valid positive earning amount
        IF earning_amount > 0.00 THEN
            -- 1. Update driver's wallet balance
            UPDATE public.drivers
            SET wallet_balance = COALESCE(wallet_balance, 0.00) + earning_amount
            WHERE id = NEW.driver_id;

            -- 2. Insert into wallet_transactions to record this earning if not already logged
            IF NOT EXISTS (
                SELECT 1 FROM public.wallet_transactions 
                WHERE order_id = NEW.id AND type = 'earning'
            ) THEN
                INSERT INTO public.wallet_transactions (
                    driver_id,
                    amount,
                    type,
                    status,
                    description,
                    order_id
                ) VALUES (
                    NEW.driver_id,
                    earning_amount,
                    'earning',
                    'completed',
                    'Earnings from Order #' || SUBSTRING(NEW.id::text, 1, 8),
                    NEW.id
                );
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on orders table
DROP TRIGGER IF EXISTS tr_order_completed_wallet_earning ON public.orders;
CREATE TRIGGER tr_order_completed_wallet_earning
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.fn_handle_driver_earning_on_order_completed();

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
