-- 16 · Star schema and slowly changing dimensions (PostgreSQL)
-- Builds a small warehouse in its own schema from the sample (OLTP) database.

SET client_min_messages = warning;
DROP SCHEMA IF EXISTS dw CASCADE;
RESET client_min_messages;
CREATE SCHEMA dw;

-- ---------------------------------------------------------------
-- 1. Date dimension: one row per day
-- ---------------------------------------------------------------
CREATE TABLE dw.dim_date (
    date_key     INT PRIMARY KEY,           -- yyyymmdd, readable and sortable
    full_date    DATE NOT NULL UNIQUE,
    year         INT  NOT NULL,
    quarter      INT  NOT NULL,
    month        INT  NOT NULL,
    month_name   TEXT NOT NULL,
    day_of_week  TEXT NOT NULL,
    is_weekend   BOOLEAN NOT NULL
);

INSERT INTO dw.dim_date
SELECT TO_CHAR(d, 'YYYYMMDD')::INT,
       d,
       EXTRACT(YEAR FROM d),
       EXTRACT(QUARTER FROM d),
       EXTRACT(MONTH FROM d),
       TO_CHAR(d, 'Mon'),
       TO_CHAR(d, 'Dy'),
       EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series(DATE '2024-01-01', DATE '2026-12-31', INTERVAL '1 day') AS g(d);

-- ---------------------------------------------------------------
-- 2. Dimensions with surrogate keys
-- ---------------------------------------------------------------
CREATE TABLE dw.dim_product (
    product_key   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id    INT  NOT NULL UNIQUE,          -- business (natural) key from the source
    product_name  TEXT NOT NULL,
    category      TEXT NOT NULL
);

INSERT INTO dw.dim_product (product_id, product_name, category)
SELECT product_id, product_name, category FROM products;

-- Customer dimension as SCD Type 2 (history kept as rows)
CREATE TABLE dw.dim_customer (
    customer_key  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id   INT  NOT NULL,                 -- business key: NOT unique, one row per version
    name          TEXT NOT NULL,
    city          TEXT,
    country       TEXT,
    valid_from    DATE NOT NULL,
    valid_to      DATE NOT NULL DEFAULT DATE '9999-12-31',
    is_current    BOOLEAN NOT NULL DEFAULT TRUE
);
-- At most one current row per customer
CREATE UNIQUE INDEX dim_customer_one_current ON dw.dim_customer (customer_id) WHERE is_current;

INSERT INTO dw.dim_customer (customer_id, name, city, country, valid_from)
SELECT customer_id, name, city, country, signup_date FROM customers;

-- ---------------------------------------------------------------
-- 3. Fact table. Grain: one row per order line
-- ---------------------------------------------------------------
CREATE TABLE dw.fact_sales (
    date_key      INT NOT NULL REFERENCES dw.dim_date (date_key),
    customer_key  INT NOT NULL REFERENCES dw.dim_customer (customer_key),
    product_key   INT NOT NULL REFERENCES dw.dim_product (product_key),
    order_id      INT NOT NULL,                  -- degenerate dimension
    status        TEXT NOT NULL,
    quantity      INT NOT NULL,                  -- additive
    revenue       NUMERIC(12,2) NOT NULL         -- additive
);

-- Look up the customer version that was valid on the order date
INSERT INTO dw.fact_sales
SELECT TO_CHAR(o.order_date, 'YYYYMMDD')::INT,
       dc.customer_key,
       dp.product_key,
       o.order_id,
       o.status,
       oi.quantity,
       oi.quantity * oi.unit_price
FROM orders o
JOIN order_items oi    ON oi.order_id = o.order_id
JOIN dw.dim_product dp ON dp.product_id = oi.product_id
JOIN dw.dim_customer dc
  ON dc.customer_id = o.customer_id
 AND o.order_date >= dc.valid_from AND o.order_date < dc.valid_to;

-- Typical star-schema query: one join per dimension, group by their attributes
SELECT d.year, d.quarter, p.category, SUM(f.revenue) AS revenue, SUM(f.quantity) AS units
FROM dw.fact_sales f
JOIN dw.dim_date d    ON d.date_key    = f.date_key
JOIN dw.dim_product p ON p.product_key = f.product_key
WHERE f.status <> 'cancelled'
GROUP BY d.year, d.quarter, p.category
ORDER BY d.year, d.quarter, revenue DESC;

-- Weekend vs weekday sales
SELECT d.is_weekend, COUNT(DISTINCT f.order_id) AS orders, SUM(f.revenue) AS revenue
FROM dw.fact_sales f JOIN dw.dim_date d ON d.date_key = f.date_key
GROUP BY d.is_weekend;

-- ---------------------------------------------------------------
-- 4. SCD Type 2 load: Aarav (1) moves to Pune on 2025-07-01,
--    Lena (8) moves to Munich on 2025-10-01, and a brand-new customer arrives.
-- ---------------------------------------------------------------
CREATE TEMP TABLE stg_customers (
    customer_id INT, name TEXT, city TEXT, country TEXT, effective_date DATE
);
INSERT INTO stg_customers VALUES
    (1,  'Aarav Shah',   'Pune',    'India',   '2025-07-01'),   -- changed
    (2,  'Isha Patel',   'Ahmedabad','India',  '2025-07-01'),   -- unchanged
    (8,  'Lena Fischer', 'Munich',  'Germany', '2025-10-01'),   -- changed
    (11, 'Nina Roy',     'Kolkata', 'India',   '2025-07-01');   -- new

BEGIN;

-- Step 1: expire the current version of every customer whose tracked attributes changed
UPDATE dw.dim_customer d
SET valid_to = s.effective_date,
    is_current = FALSE
FROM stg_customers s
WHERE d.customer_id = s.customer_id
  AND d.is_current
  AND (d.city, d.country) IS DISTINCT FROM (s.city, s.country);

-- Step 2: insert a new current version for changed customers and brand-new ones
INSERT INTO dw.dim_customer (customer_id, name, city, country, valid_from)
SELECT s.customer_id, s.name, s.city, s.country, s.effective_date
FROM stg_customers s
WHERE NOT EXISTS (
    SELECT 1 FROM dw.dim_customer d WHERE d.customer_id = s.customer_id AND d.is_current
);

COMMIT;

-- Result: two versions each for Aarav and Lena, one for the new customer.
-- Re-running steps 1 and 2 with the same staging data changes nothing (idempotent).
SELECT customer_key, customer_id, name, city, valid_from, valid_to, is_current
FROM dw.dim_customer
WHERE customer_id IN (1, 8, 11)
ORDER BY customer_id, valid_from;

-- Re-point facts for orders placed after the move (only needed here because we
-- loaded facts before the dimension changes; a real pipeline loads dims first)
UPDATE dw.fact_sales f
SET customer_key = dc.customer_key
FROM dw.dim_date d, orders o, dw.dim_customer dc
WHERE d.date_key = f.date_key
  AND o.order_id = f.order_id
  AND dc.customer_id = o.customer_id
  AND d.full_date >= dc.valid_from AND d.full_date < dc.valid_to
  AND f.customer_key <> dc.customer_key;

-- Revenue by the customer's city AT THE TIME of the sale (history preserved):
-- Aarav's early orders count for Mumbai, his December order for Pune
SELECT c.name, c.city, COUNT(DISTINCT f.order_id) AS orders, SUM(f.revenue) AS revenue
FROM dw.fact_sales f
JOIN dw.dim_customer c ON c.customer_key = f.customer_key
WHERE c.customer_id = 1
GROUP BY c.name, c.city;

-- Revenue by the customer's CURRENT city (join through the business key to the current row)
SELECT cur.city, SUM(f.revenue) AS revenue
FROM dw.fact_sales f
JOIN dw.dim_customer hist ON hist.customer_key = f.customer_key
JOIN dw.dim_customer cur  ON cur.customer_id = hist.customer_id AND cur.is_current
WHERE cur.customer_id = 1
GROUP BY cur.city;

-- Point-in-time lookup: where did each customer live on 2025-08-15?
SELECT customer_id, name, city
FROM dw.dim_customer
WHERE DATE '2025-08-15' >= valid_from AND DATE '2025-08-15' < valid_to
  AND customer_id IN (1, 8)
ORDER BY customer_id;

-- ---------------------------------------------------------------
-- 5. SCD Type 1: overwrite (no history). A product is renamed.
-- ---------------------------------------------------------------
UPDATE dw.dim_product SET product_name = 'Laptop Pro 14 (2025)' WHERE product_id = 1;
-- Every past sale now reports the new name.

-- ---------------------------------------------------------------
-- 6. SCD Type 3: keep only the previous value in an extra column
-- ---------------------------------------------------------------
ALTER TABLE dw.dim_product ADD COLUMN previous_category TEXT;
UPDATE dw.dim_product
SET previous_category = category,
    category = 'Office Supplies'
WHERE category = 'Stationery';
SELECT product_name, category, previous_category FROM dw.dim_product WHERE previous_category IS NOT NULL;

-- ---------------------------------------------------------------
-- 7. Periodic snapshot fact: stock level per product at each month end
-- ---------------------------------------------------------------
CREATE TABLE dw.fact_stock_snapshot (
    date_key     INT REFERENCES dw.dim_date (date_key),
    product_key  INT REFERENCES dw.dim_product (product_key),
    stock        INT NOT NULL,          -- semi-additive: sum across products, NOT across months
    PRIMARY KEY (date_key, product_key)
);

INSERT INTO dw.fact_stock_snapshot
SELECT 20251231, dp.product_key, p.stock
FROM products p JOIN dw.dim_product dp ON dp.product_id = p.product_id;

-- Correct: total stock on one date. (Summing over many dates would be meaningless.)
SELECT SUM(stock) AS units_in_stock FROM dw.fact_stock_snapshot WHERE date_key = 20251231;

SET client_min_messages = warning;
DROP SCHEMA dw CASCADE;
