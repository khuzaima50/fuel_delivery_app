-- 20260420_prevent_completed_order_update.sql

CREATE OR REPLACE FUNCTION prevent_completed_order_update()
RETURNS TRIGGER AS $$
BEGIN
    -- If the order is already in a terminal state ('completed' or 'delivered')
    IF OLD.status IN ('completed', 'delivered') THEN
        -- Prevent changing the status to anything else
        IF NEW.status != OLD.status THEN
            RAISE EXCEPTION 'Cannot change the status of an already completed or delivered order.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_completed_order_update ON public.orders;

CREATE TRIGGER trg_prevent_completed_order_update
BEFORE UPDATE ON public.orders
FOR EACH ROW
EXECUTE FUNCTION prevent_completed_order_update();
