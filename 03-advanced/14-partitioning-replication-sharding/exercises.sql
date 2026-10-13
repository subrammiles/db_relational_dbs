-- 14 · Exercises with solutions

SET client_min_messages = warning;
DROP TABLE IF EXISTS app_logs, tenant_data;
RESET client_min_messages;

-- 1. Create `app_logs (log_id, logged_at TIMESTAMPTZ, level, message)` partitioned by month
--    for Jan-Mar 2026, plus a default partition.
CREATE TABLE app_logs (
    log_id     BIGINT      NOT NULL,
    logged_at  TIMESTAMPTZ NOT NULL,
    level      TEXT        NOT NULL,
    message    TEXT
) PARTITION BY RANGE (logged_at);

CREATE TABLE app_logs_2026_01 PARTITION OF app_logs FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE app_logs_2026_02 PARTITION OF app_logs FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE app_logs_2026_03 PARTITION OF app_logs FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE app_logs_default PARTITION OF app_logs DEFAULT;

INSERT INTO app_logs
SELECT g, TIMESTAMPTZ '2026-01-01' + (g % 100) * INTERVAL '1 day', (ARRAY['INFO','WARN','ERROR'])[1 + g % 3], 'msg ' || g
FROM generate_series(1, 9000) g;
ANALYZE app_logs;

-- 2. How many rows landed in each partition? (Days 90-99 fall into April → default.)
SELECT tableoid::regclass AS partition, COUNT(*) FROM app_logs GROUP BY 1 ORDER BY 1;

-- 3. Show that a February query only scans the February partition.
EXPLAIN SELECT COUNT(*) FROM app_logs
WHERE logged_at >= '2026-02-01' AND logged_at < '2026-03-01' AND level = 'ERROR';

-- 4. Retention policy: logs older than February must go. Remove January instantly.
ALTER TABLE app_logs DETACH PARTITION app_logs_2026_01;
DROP TABLE app_logs_2026_01;

-- 5. April data is sitting in the default partition. Create a proper April partition and move it.
--    (A new partition can't be attached while the default holds rows for its range.)
BEGIN;
CREATE TABLE app_logs_2026_04 (LIKE app_logs INCLUDING ALL);
INSERT INTO app_logs_2026_04 SELECT * FROM app_logs_default WHERE logged_at >= '2026-04-01' AND logged_at < '2026-05-01';
DELETE FROM app_logs_default WHERE logged_at >= '2026-04-01' AND logged_at < '2026-05-01';
ALTER TABLE app_logs ATTACH PARTITION app_logs_2026_04 FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
COMMIT;
SELECT tableoid::regclass AS partition, COUNT(*) FROM app_logs GROUP BY 1 ORDER BY 1;

-- 6. Multi-tenant SaaS table: spread tenants evenly over 4 partitions, and confirm that a
--    query for one tenant touches one partition (the same idea a sharding key relies on).
CREATE TABLE tenant_data (tenant_id INT NOT NULL, item TEXT) PARTITION BY HASH (tenant_id);
CREATE TABLE tenant_data_0 PARTITION OF tenant_data FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE tenant_data_1 PARTITION OF tenant_data FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE tenant_data_2 PARTITION OF tenant_data FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE tenant_data_3 PARTITION OF tenant_data FOR VALUES WITH (MODULUS 4, REMAINDER 3);
INSERT INTO tenant_data SELECT g % 200, 'item ' || g FROM generate_series(1, 10000) g;
EXPLAIN SELECT * FROM tenant_data WHERE tenant_id = 17;

-- 7. Design questions (answers in comments):
--  a) Orders table of 2 TB, queries almost always filter by order_date, data kept 7 years.
--     → RANGE partition by month (or year) on order_date; drop old partitions for retention.
--  b) Reads overload the primary, writes are fine.
--     → Add read replicas; route read-only queries there; read-after-write goes to the primary.
--  c) Writes exceed what one server can handle, data is per tenant.
--     → Shard by tenant_id (Citus/Vitess or app-level routing); keep tenant data together.

DROP TABLE app_logs, tenant_data;
