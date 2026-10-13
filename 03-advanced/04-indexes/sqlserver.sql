-- 04 · Indexes in SQL Server (T-SQL)
-- The PRIMARY KEY is a CLUSTERED index by default: the table rows are stored in key order.

DROP TABLE IF EXISTS big_orders;
CREATE TABLE big_orders (
    order_id     INT NOT NULL,
    customer_id  INT NOT NULL,
    order_date   DATE NOT NULL,
    status       VARCHAR(20) NOT NULL,
    amount       DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_big_orders PRIMARY KEY CLUSTERED (order_id)
);

INSERT INTO big_orders (order_id, customer_id, order_date, status, amount)
SELECT value, 1 + value % 20000, DATEADD(DAY, value % 1100, '2023-01-01'),
       CHOOSE(1 + value % 4, 'delivered', 'shipped', 'pending', 'cancelled'),
       (value % 5000) / 1.0
FROM GENERATE_SERIES(1, 200000);

-- Nonclustered index with INCLUDE: a covering index for the query below
CREATE NONCLUSTERED INDEX ix_big_orders_customer
ON big_orders (customer_id, order_date DESC)
INCLUDE (amount);

-- Filtered index (like a partial index)
CREATE NONCLUSTERED INDEX ix_big_orders_pending
ON big_orders (order_date)
WHERE status = 'pending';

-- Show the actual plan as text: look for "Index Seek" vs "Clustered Index Scan"
SET STATISTICS PROFILE ON;
SELECT TOP (10) order_date, amount FROM big_orders WHERE customer_id = 42 ORDER BY order_date DESC;  -- Index Seek, covered
SELECT COUNT(*) FROM big_orders WHERE YEAR(order_date) = 2024;                                        -- scan: not sargable
SELECT COUNT(*) FROM big_orders WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01';     -- clustered scan or seek, depending on indexes
SET STATISTICS PROFILE OFF;

-- I/O per query
SET STATISTICS IO ON;
SELECT amount FROM big_orders WHERE customer_id = 42;
SET STATISTICS IO OFF;

-- Index usage and the optimizer's own "missing index" suggestions
SELECT i.name, s.user_seeks, s.user_scans, s.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s
       ON s.object_id = i.object_id AND s.index_id = i.index_id AND s.database_id = DB_ID()
WHERE i.object_id = OBJECT_ID('big_orders');

SELECT TOP (5) d.statement, d.equality_columns, d.inequality_columns, d.included_columns
FROM sys.dm_db_missing_index_details d
WHERE d.database_id = DB_ID();

-- Maintenance
ALTER INDEX ix_big_orders_customer ON big_orders REBUILD;
UPDATE STATISTICS big_orders;

DROP TABLE big_orders;
