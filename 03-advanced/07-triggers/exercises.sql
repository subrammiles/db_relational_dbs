-- 07 · Exercises with solutions

-- 1. Prevent deleting a customer who has orders, with a clear message.
--    (A foreign key already blocks it; a trigger lets you customise the error.)
CREATE OR REPLACE FUNCTION protect_customers()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM orders WHERE customer_id = OLD.customer_id) THEN
        RAISE EXCEPTION 'Customer % has orders and cannot be deleted', OLD.name;
    END IF;
    RETURN OLD;               -- for BEFORE DELETE, return OLD to let the delete proceed
END;
$$;

CREATE TRIGGER trg_protect_customers
BEFORE DELETE ON customers
FOR EACH ROW
EXECUTE FUNCTION protect_customers();

DELETE FROM customers WHERE customer_id = 9;          -- Omar has no orders: allowed
DO $$
BEGIN
    DELETE FROM customers WHERE customer_id = 1;
EXCEPTION WHEN raise_exception THEN
    RAISE NOTICE '%', SQLERRM;
END $$;

-- 2. Record every order status change in an order_history table.
CREATE TABLE order_history (
    order_id    INT,
    old_status  VARCHAR(20),
    new_status  VARCHAR(20),
    changed_at  TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION log_status()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO order_history (order_id, old_status, new_status)
    VALUES (NEW.order_id, OLD.status, NEW.status);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_order_status
AFTER UPDATE OF status ON orders
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION log_status();

UPDATE orders SET status = 'delivered' WHERE status = 'shipped';
SELECT order_id, old_status, new_status FROM order_history;

DROP TRIGGER trg_order_status ON orders;
DROP TRIGGER trg_protect_customers ON customers;
DROP FUNCTION log_status, protect_customers;
DROP TABLE order_history;
