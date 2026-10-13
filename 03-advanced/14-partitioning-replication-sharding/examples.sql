-- 14 · Partitioning (PostgreSQL 11+)

SET client_min_messages = warning;
DROP TABLE IF EXISTS events, sales_by_region, sessions;
RESET client_min_messages;

-- ---------------------------------------------------------------
-- 1. RANGE partitioning by date
-- ---------------------------------------------------------------
CREATE TABLE events (
    event_id    BIGINT       NOT NULL,
    created_at  DATE         NOT NULL,
    kind        VARCHAR(20)  NOT NULL,
    payload     TEXT,
    PRIMARY KEY (event_id, created_at)        -- must include the partition key
) PARTITION BY RANGE (created_at);

CREATE TABLE events_2024 PARTITION OF events FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
CREATE TABLE events_2025 PARTITION OF events FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
CREATE TABLE events_2026 PARTITION OF events FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');
CREATE TABLE events_default PARTITION OF events DEFAULT;    -- catches anything else

-- Rows are routed to the right partition automatically
INSERT INTO events (event_id, created_at, kind)
SELECT g, DATE '2024-01-01' + (g % 1000), (ARRAY['click','view','buy'])[1 + g % 3]
FROM generate_series(1, 30000) g;

ANALYZE events;

-- Where did the rows go?
SELECT tableoid::regclass AS partition, COUNT(*), MIN(created_at), MAX(created_at)
FROM events
GROUP BY 1
ORDER BY 1;

-- Partition pruning: only events_2025 is scanned
EXPLAIN SELECT COUNT(*) FROM events WHERE created_at >= '2025-03-01' AND created_at < '2025-04-01';

-- No filter on the partition key: every partition is scanned
EXPLAIN SELECT COUNT(*) FROM events WHERE kind = 'buy';

-- An index on the parent is created on every partition
CREATE INDEX events_kind_idx ON events (kind);

-- Data lifecycle: removing a whole year is instant (vs DELETE of 10k+ rows)
ALTER TABLE events DETACH PARTITION events_2024;     -- now a normal standalone table (could be archived)
DROP TABLE events_2024;
SELECT MIN(created_at) AS oldest_remaining FROM events;

-- Add next year's partition ahead of time
CREATE TABLE events_2027 PARTITION OF events FOR VALUES FROM ('2027-01-01') TO ('2028-01-01');

-- ---------------------------------------------------------------
-- 2. LIST partitioning by region
-- ---------------------------------------------------------------
CREATE TABLE sales_by_region (
    sale_id  INT,
    country  VARCHAR(20) NOT NULL,
    amount   NUMERIC(10,2)
) PARTITION BY LIST (country);

CREATE TABLE sales_apac   PARTITION OF sales_by_region FOR VALUES IN ('India', 'China');
CREATE TABLE sales_europe PARTITION OF sales_by_region FOR VALUES IN ('UK', 'Spain', 'Germany');
CREATE TABLE sales_other  PARTITION OF sales_by_region DEFAULT;

INSERT INTO sales_by_region
SELECT o.order_id, c.country, SUM(oi.quantity * oi.unit_price)
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
GROUP BY o.order_id, c.country;

SELECT tableoid::regclass AS partition, COUNT(*) AS orders, SUM(amount) AS revenue
FROM sales_by_region GROUP BY 1 ORDER BY 1;

EXPLAIN SELECT SUM(amount) FROM sales_by_region WHERE country = 'UK';   -- only sales_europe

-- ---------------------------------------------------------------
-- 3. HASH partitioning: spread rows evenly across N partitions
-- ---------------------------------------------------------------
CREATE TABLE sessions (
    session_id  BIGINT NOT NULL,
    user_id     INT    NOT NULL,
    started_at  TIMESTAMPTZ DEFAULT now()
) PARTITION BY HASH (user_id);

CREATE TABLE sessions_p0 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE sessions_p1 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE sessions_p2 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE sessions_p3 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 3);

INSERT INTO sessions (session_id, user_id) SELECT g, g % 1000 FROM generate_series(1, 20000) g;

SELECT tableoid::regclass AS partition, COUNT(*) FROM sessions GROUP BY 1 ORDER BY 1;   -- roughly equal
EXPLAIN SELECT * FROM sessions WHERE user_id = 42;      -- one partition

DROP TABLE events, sales_by_region, sessions;
