-- 08 · Exercises with solutions (wrapped in a transaction and rolled back)

BEGIN;

-- 1. Give Emma Brown (customer 6) the email 'emma@mail.com'.
UPDATE customers SET email = 'emma@mail.com' WHERE customer_id = 6;

-- 2. Increase the price of all Stationery products by 10%.
UPDATE products SET price = price * 1.10 WHERE category = 'Stationery';

-- 3. Mark every 'shipped' order as 'delivered'.
UPDATE orders SET status = 'delivered' WHERE status = 'shipped';

-- 4. Delete products that have never been ordered.
DELETE FROM products p
WHERE NOT EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.product_id);

-- 5. Delete customers who have never placed an order and show who was deleted.
DELETE FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)
RETURNING name;

ROLLBACK;
