-- 10 · Exercises with solutions
-- A larger copy of orders to make plans meaningful.

DROP TABLE IF EXISTS x_orders;
CREATE TABLE x_orders AS
SELECT g AS order_id,
       1 + (g % 5000) AS customer_id,
       DATE '2023-01-01' + (g % 1000) AS order_date,
       (ARRAY['pending','shipped','delivered','delivered','delivered','cancelled'])[1 + g % 6] AS status,
       ((g * 37) % 10000)::NUMERIC / 10 AS amount
FROM generate_series(1, 200000) g;
ALTER TABLE x_orders ADD PRIMARY KEY (order_id);
ANALYZE x_orders;

-- 1. This query is slow. Make it sargable and add the index it needs.
--    SELECT COUNT(*) FROM x_orders WHERE TO_CHAR(order_date, 'YYYY-MM') = '2024-03';
CREATE INDEX x_orders_date_idx ON x_orders (order_date);
EXPLAIN SELECT COUNT(*) FROM x_orders WHERE order_date >= '2024-03-01' AND order_date < '2024-04-01';

-- 2. The app's hottest query is: latest 10 orders of one customer.
--    Which single index serves both the filter and the sort?
CREATE INDEX x_orders_cust_date_idx ON x_orders (customer_id, order_date DESC);
EXPLAIN SELECT * FROM x_orders WHERE customer_id = 42 ORDER BY order_date DESC LIMIT 10;   -- no Sort node

-- 3. Rewrite to avoid scanning and sorting for DISTINCT:
--    SELECT DISTINCT customer_id FROM x_orders WHERE status = 'cancelled' AND amount > 990;
--    → If the intent is "customers with at least one such order", EXISTS on the customer list is clearer;
--      here a partial index makes the filter itself cheap:
CREATE INDEX x_orders_cancelled_big ON x_orders (customer_id) WHERE status = 'cancelled' AND amount > 990;
EXPLAIN SELECT DISTINCT customer_id FROM x_orders WHERE status = 'cancelled' AND amount > 990;

-- 4. Find the estimate-vs-actual problem. Statistics are disabled on purpose, then fixed.
ALTER TABLE x_orders SET (autovacuum_enabled = off);
INSERT INTO x_orders
SELECT 200000 + g, 99999, DATE '2026-01-01', 'pending', 1 FROM generate_series(1, 50000) g;
EXPLAIN SELECT * FROM x_orders WHERE customer_id = 99999;     -- estimates ~50 rows; reality is 50,000
ANALYZE x_orders;
EXPLAIN SELECT * FROM x_orders WHERE customer_id = 99999;     -- estimate now ~50,000
-- A 1000x misestimate like this can make the planner pick a nested loop where a hash join
-- was needed, the wrong join order, or too little memory for a sort. Compare with EXPLAIN ANALYZE.

-- 5. Replace this correlated subquery with a set-based query:
--    SELECT customer_id, (SELECT MAX(order_date) FROM x_orders o2 WHERE o2.customer_id = o.customer_id)
--    FROM (SELECT DISTINCT customer_id FROM x_orders) o;
SELECT customer_id, MAX(order_date) AS last_order
FROM x_orders
GROUP BY customer_id;

DROP TABLE x_orders;
