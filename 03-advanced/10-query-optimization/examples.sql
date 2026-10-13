-- 10 · Query optimization (PostgreSQL)
-- Builds two larger tables so the planner has real choices to make.

SET client_min_messages = warning;   -- hide "does not exist, skipping"
DROP TABLE IF EXISTS q_orders, q_customers;
RESET client_min_messages;

CREATE TABLE q_customers (
    customer_id  INT PRIMARY KEY,
    country      VARCHAR(20) NOT NULL,
    signup_date  DATE NOT NULL
);

CREATE TABLE q_orders (
    order_id     INT PRIMARY KEY,
    customer_id  INT NOT NULL REFERENCES q_customers (customer_id),
    order_date   DATE NOT NULL,
    amount       NUMERIC(10,2) NOT NULL
);

INSERT INTO q_customers
SELECT g,
       (ARRAY['India','UK','USA','Germany','Spain'])[1 + g % 5],
       DATE '2020-01-01' + (g % 2000)
FROM generate_series(1, 50000) g;

INSERT INTO q_orders
SELECT g, 1 + ((g::BIGINT * 7919) % 50000)::INT, DATE '2023-01-01' + (g % 1000), (g % 997) + 0.5
FROM generate_series(1, 300000) g;

ANALYZE q_customers;
ANALYZE q_orders;

-- ---------------------------------------------------------------
-- 1. Reading EXPLAIN ANALYZE: estimated vs actual rows, time per node
-- ---------------------------------------------------------------
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.country, SUM(o.amount)
FROM q_orders o
JOIN q_customers c ON c.customer_id = o.customer_id
GROUP BY c.country;
-- Expect: Seq Scans on both tables → Hash Join → HashAggregate

-- ---------------------------------------------------------------
-- 2. Join algorithms
-- ---------------------------------------------------------------
-- No index on q_orders.customer_id, few customers selected:
EXPLAIN SELECT * FROM q_customers c JOIN q_orders o ON o.customer_id = c.customer_id
WHERE c.customer_id BETWEEN 1 AND 5;
-- Probably a Hash Join or a Nested Loop over a Seq Scan of q_orders: every order is read.

-- Index the foreign key...
CREATE INDEX q_orders_customer_idx ON q_orders (customer_id);
ANALYZE q_orders;

-- ...and the same query becomes a Nested Loop doing index lookups
EXPLAIN SELECT * FROM q_customers c JOIN q_orders o ON o.customer_id = c.customer_id
WHERE c.customer_id BETWEEN 1 AND 5;

-- Both inputs read in key order → Merge Join is an option
SET enable_hashjoin = off;   -- for demonstration only: nudge the planner
EXPLAIN SELECT c.customer_id, o.order_id FROM q_customers c JOIN q_orders o ON o.customer_id = c.customer_id;
RESET enable_hashjoin;

-- ---------------------------------------------------------------
-- 3. Sargable rewrites
-- ---------------------------------------------------------------
CREATE INDEX q_orders_date_idx ON q_orders (order_date);

EXPLAIN ANALYZE SELECT COUNT(*) FROM q_orders WHERE date_part('year', order_date) = 2024;      -- whole table/index
EXPLAIN ANALYZE SELECT COUNT(*) FROM q_orders WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01';

EXPLAIN SELECT * FROM q_orders WHERE order_id + 0 = 500;     -- expression on the column: Seq Scan
EXPLAIN SELECT * FROM q_orders WHERE order_id = 500;         -- Index Scan

-- ---------------------------------------------------------------
-- 4. Correlated subquery in SELECT vs join + GROUP BY vs window
-- ---------------------------------------------------------------
-- Per-row subquery: runs once for each of the selected customers
EXPLAIN ANALYZE
SELECT c.customer_id,
       (SELECT COUNT(*) FROM q_orders o WHERE o.customer_id = c.customer_id) AS orders
FROM q_customers c
WHERE c.country = 'UK';

-- Set-based: aggregate once, then join
EXPLAIN ANALYZE
SELECT c.customer_id, COALESCE(t.orders, 0) AS orders
FROM q_customers c
LEFT JOIN (SELECT customer_id, COUNT(*) AS orders FROM q_orders GROUP BY customer_id) t
       ON t.customer_id = c.customer_id
WHERE c.country = 'UK';

-- ---------------------------------------------------------------
-- 5. EXISTS instead of JOIN + DISTINCT
-- ---------------------------------------------------------------
EXPLAIN ANALYZE
SELECT DISTINCT c.customer_id FROM q_customers c JOIN q_orders o ON o.customer_id = c.customer_id
WHERE o.amount > 990;

EXPLAIN ANALYZE
SELECT c.customer_id FROM q_customers c
WHERE EXISTS (SELECT 1 FROM q_orders o WHERE o.customer_id = c.customer_id AND o.amount > 990);

-- ---------------------------------------------------------------
-- 6. The N+1 pattern (what an ORM loop does) vs one query
-- ---------------------------------------------------------------
-- N+1: 1 query for the customers, then one query per customer
DO $$
DECLARE
    r RECORD;
    n BIGINT;
    t0 TIMESTAMPTZ := clock_timestamp();
BEGIN
    FOR r IN SELECT customer_id FROM q_customers WHERE customer_id <= 2000 LOOP
        SELECT COUNT(*) INTO n FROM q_orders WHERE customer_id = r.customer_id;
    END LOOP;
    RAISE NOTICE 'N+1 queries:  % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - t0) * 1000);
END $$;

-- One query
DO $$
DECLARE
    t0 TIMESTAMPTZ := clock_timestamp();
BEGIN
    PERFORM customer_id, COUNT(*) FROM q_orders WHERE customer_id <= 2000 GROUP BY customer_id;
    RAISE NOTICE 'Single query: % ms', round(EXTRACT(EPOCH FROM clock_timestamp() - t0) * 1000);
END $$;
-- Inside the database both are fast; over a network each of the 2000 round trips adds latency.

-- ---------------------------------------------------------------
-- 7. Stale statistics produce bad estimates
-- ---------------------------------------------------------------
CREATE TABLE q_events (id INT, kind TEXT);
ALTER TABLE q_events SET (autovacuum_enabled = off);   -- so autovacuum doesn't fix it behind our back
INSERT INTO q_events SELECT g, 'a' FROM generate_series(1, 1000) g;
ANALYZE q_events;
INSERT INTO q_events SELECT g, 'b' FROM generate_series(1, 100000) g;
EXPLAIN SELECT * FROM q_events WHERE kind = 'b';        -- estimate is far too low: stats say there are no 'b' rows
ANALYZE q_events;
EXPLAIN SELECT * FROM q_events WHERE kind = 'b';        -- estimate now ~100000

-- ---------------------------------------------------------------
-- 8. Finding slow queries in production (needs the extension):
--   CREATE EXTENSION pg_stat_statements;
--   SELECT query, calls, mean_exec_time, total_exec_time
--   FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
-- ---------------------------------------------------------------

DROP TABLE q_events, q_orders, q_customers;
