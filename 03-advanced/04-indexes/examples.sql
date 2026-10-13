-- 04 · Indexes (PostgreSQL)
-- The sample tables are too small for indexes to matter, so we generate a big one.
-- Run the EXPLAIN lines one at a time and compare the plans.

DROP TABLE IF EXISTS big_orders;
CREATE TABLE big_orders (
    order_id     INT PRIMARY KEY,
    customer_id  INT          NOT NULL,
    order_date   DATE         NOT NULL,
    status       VARCHAR(20)  NOT NULL,
    amount       NUMERIC(10,2) NOT NULL,
    email        VARCHAR(100) NOT NULL
);

-- 200,000 rows: 20,000 customers, dates over ~3 years, 4 statuses
INSERT INTO big_orders
SELECT g,
       1 + (g % 20000),
       DATE '2023-01-01' + (g % 1100),
       (ARRAY['delivered','delivered','delivered','shipped','pending','cancelled'])[1 + g % 6],
       ROUND((random() * 5000)::NUMERIC, 2),
       'user' || (1 + (g % 20000)) || '@Mail.com'
FROM generate_series(1, 200000) AS g;

ANALYZE big_orders;            -- refresh planner statistics after a bulk load

-- 1. Primary key lookup: Index Scan using big_orders_pkey
EXPLAIN SELECT * FROM big_orders WHERE order_id = 12345;

-- 2. No index on customer_id yet: Seq Scan over all 200k rows
EXPLAIN ANALYZE SELECT * FROM big_orders WHERE customer_id = 42;

CREATE INDEX idx_big_orders_customer ON big_orders (customer_id);

-- Now: Bitmap/Index Scan on idx_big_orders_customer, far fewer rows read
EXPLAIN ANALYZE SELECT * FROM big_orders WHERE customer_id = 42;

-- 3. Composite index and the leftmost-prefix rule
CREATE INDEX idx_big_orders_cust_date ON big_orders (customer_id, order_date);

EXPLAIN SELECT * FROM big_orders WHERE customer_id = 42 AND order_date >= '2025-01-01';  -- uses it
EXPLAIN SELECT * FROM big_orders WHERE customer_id = 42 ORDER BY order_date;             -- can read rows already sorted (with only 10 rows the planner may just sort them)
EXPLAIN SELECT * FROM big_orders WHERE order_date = '2025-01-01';                        -- leading column missing: no direct lookup; it scans the whole index (note the much higher cost)

-- 4. Covering index → Index Only Scan (the table itself isn't read)
CREATE INDEX idx_big_orders_cust_cov ON big_orders (customer_id) INCLUDE (amount);
VACUUM big_orders;             -- index-only scans need an up-to-date visibility map
EXPLAIN SELECT customer_id, amount FROM big_orders WHERE customer_id BETWEEN 100 AND 200;

-- 5. Functions on the column defeat a normal index...
CREATE INDEX idx_big_orders_email ON big_orders (email);
EXPLAIN SELECT * FROM big_orders WHERE LOWER(email) = 'user42@mail.com';   -- Seq Scan
-- ...unless you index the expression
CREATE INDEX idx_big_orders_email_lower ON big_orders (LOWER(email));
EXPLAIN SELECT * FROM big_orders WHERE LOWER(email) = 'user42@mail.com';   -- uses idx_big_orders_email_lower

-- 6. Non-sargable vs sargable date filter
CREATE INDEX idx_big_orders_date ON big_orders (order_date);
EXPLAIN SELECT COUNT(*) FROM big_orders WHERE EXTRACT(YEAR FROM order_date) = 2023 AND EXTRACT(MONTH FROM order_date) = 6;  -- reads EVERY index entry (cost ~5000)
EXPLAIN SELECT COUNT(*) FROM big_orders WHERE order_date >= '2023-06-01' AND order_date < '2023-07-01';                     -- reads only June's entries (cost ~130)

-- 7. Leading wildcard can't use a B-tree
EXPLAIN SELECT * FROM big_orders WHERE email LIKE '%42@Mail.com';          -- Seq Scan

-- 8. Partial index: only the rows you query often (pending is ~1/6 of the table)
CREATE INDEX idx_big_orders_pending ON big_orders (order_date) WHERE status = 'pending';
EXPLAIN SELECT * FROM big_orders WHERE status = 'pending' AND order_date >= '2025-12-01';

-- 9. Selectivity: an index helps when it narrows the search down to few rows
CREATE INDEX idx_big_orders_status ON big_orders (status);
EXPLAIN SELECT * FROM big_orders WHERE status = 'delivered';               -- ~100,000 rows (50%): the index barely helps, look at the cost
EXPLAIN SELECT * FROM big_orders WHERE status = 'cancelled' AND customer_id = 7;  -- picks the selective index

-- Index sizes vs table size: indexes are not free
SELECT relname AS name, pg_size_pretty(pg_relation_size(oid)) AS size
FROM pg_class
WHERE relname LIKE 'big_orders%' OR relname LIKE 'idx_big_orders%'
ORDER BY pg_relation_size(oid) DESC;

-- Which indexes exist, and have they been used?
SELECT indexrelname AS index, idx_scan AS times_used
FROM pg_stat_user_indexes
WHERE relname = 'big_orders'
ORDER BY idx_scan DESC;

-- Index on a foreign key in the sample DB (PostgreSQL doesn't create these automatically)
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_employees_dept_id ON employees (dept_id);

DROP TABLE big_orders;   -- drops its indexes too
