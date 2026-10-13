-- 05 · Exercises with solutions

-- 1. Place a new order 19 for customer 9 containing 2 Wireless Mice at list price,
--    and reduce stock, as one atomic unit.
BEGIN;
INSERT INTO orders (order_id, customer_id, order_date, status) VALUES (19, 9, CURRENT_DATE, 'pending');
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT 19, product_id, 2, price FROM products WHERE product_id = 2;
UPDATE products SET stock = stock - 2 WHERE product_id = 2;
COMMIT;

-- 2. Try to sell 5 Desk Lamps (stock 0). The CHECK (stock >= 0) must make the
--    whole order fail, leaving no half-written order behind.
DO $$
BEGIN
    INSERT INTO orders (order_id, customer_id, order_date, status) VALUES (20, 10, CURRENT_DATE, 'pending');
    INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (20, 10, 5, 1800);
    UPDATE products SET stock = stock - 5 WHERE product_id = 10;     -- violates CHECK
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'Order 20 rejected: %', SQLERRM;
END $$;
SELECT COUNT(*) AS order_20_exists FROM orders WHERE order_id = 20;   -- 0

-- 3. Give every Sales employee a 10% raise but undo it for Rohan (emp 10) using a savepoint.
BEGIN;
UPDATE employees SET salary = salary * 1.10 WHERE dept_id = 2 AND emp_id <> 10;
SAVEPOINT before_rohan;
UPDATE employees SET salary = salary * 1.10 WHERE emp_id = 10;
ROLLBACK TO SAVEPOINT before_rohan;
COMMIT;
SELECT first_name, salary FROM employees WHERE dept_id = 2 ORDER BY emp_id;
