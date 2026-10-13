-- 04 · Exercises with solutions
-- For each query, decide which index would help, create it, and check with EXPLAIN.

-- 1. A frequent query: orders of one customer, newest first.
--    SELECT * FROM orders WHERE customer_id = ? ORDER BY order_date DESC;
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date DESC);
EXPLAIN SELECT * FROM orders WHERE customer_id = 1 ORDER BY order_date DESC;
-- (With 18 rows the planner may still prefer a Seq Scan. That's correct behaviour for tiny tables.)

-- 2. Case-insensitive login lookup:  WHERE LOWER(email) = LOWER(?)
CREATE UNIQUE INDEX idx_customers_email_lower ON customers (LOWER(email));

-- 3. A dashboard lists only pending orders by date. Index only those rows.
CREATE INDEX idx_orders_pending ON orders (order_date) WHERE status = 'pending';

-- 4. Rewrite to be sargable:  WHERE EXTRACT(YEAR FROM hire_date) = 2020
SELECT first_name FROM employees
WHERE hire_date >= DATE '2020-01-01' AND hire_date < DATE '2021-01-01';

-- 5. Rewrite to be sargable:  WHERE salary * 12 > 1200000
SELECT first_name FROM employees WHERE salary > 100000;

-- 6. Force the planner to show the index on a tiny table (for learning only, never in production)
SET enable_seqscan = off;
EXPLAIN SELECT * FROM orders WHERE customer_id = 1 ORDER BY order_date DESC;
RESET enable_seqscan;

-- 7. List all indexes on the orders table.
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'orders';
