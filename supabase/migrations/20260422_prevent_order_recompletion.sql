-- Description: Prevent status updates for orders that are already completed or delivered.
-- This ensures an order can only be completed exactly once.

CREATE OR REPLACE FUNCTION public.fn_lock_completed_orders()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the existing status is already a final state
    IF (OLD.status = 'completed' OR OLD.status = 'delivered') THEN
        -- If an attempt is made to change the status, block it
        IF (NEW.status IS DISTINCT FROM OLD.status) THEN
            RAISE EXCEPTION 'Order ID % is already % and its status cannot be changed.', OLD.id, OLD.status;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply the trigger before update
DROP TRIGGER IF EXISTS trig_lock_completed_orders ON public.orders;
CREATE TRIGGER trig_lock_completed_orders
BEFORE UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION public.fn_lock_completed_orders();

-- Refresh schema cache
NOTIFY pgrst, 'reload schema';
