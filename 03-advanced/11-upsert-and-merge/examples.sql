-- 11 · Upsert and MERGE (PostgreSQL 15+)

-- ---------------------------------------------------------------
-- 1. ON CONFLICT DO NOTHING: insert if new, otherwise skip silently
-- ---------------------------------------------------------------
INSERT INTO departments (dept_id, dept_name, location)
VALUES (1, 'Engineering', 'Bangalore'),          -- exists: skipped
       (7, 'Legal', 'Pune')                       -- new: inserted
ON CONFLICT (dept_id) DO NOTHING;

SELECT * FROM departments ORDER BY dept_id;

-- ---------------------------------------------------------------
-- 2. ON CONFLICT DO UPDATE: insert or update
--    EXCLUDED is the row you tried to insert; products.* is the existing row
-- ---------------------------------------------------------------
INSERT INTO products (product_id, product_name, category, price, stock)
VALUES (2,  'Wireless Mouse', 'Electronics',  750, 50),     -- exists: price updated, stock added
       (11, 'Webcam HD',      'Electronics', 3500, 40)      -- new
ON CONFLICT (product_id)
DO UPDATE SET price = EXCLUDED.price,
              stock = products.stock + EXCLUDED.stock
RETURNING product_id, product_name, price, stock, (xmax = 0) AS inserted;   -- xmax = 0 → row was inserted

-- Conflict on a different unique column (dept_name is UNIQUE)
INSERT INTO departments (dept_id, dept_name, location)
VALUES (8, 'Sales', 'Kolkata')
ON CONFLICT (dept_name) DO UPDATE SET location = EXCLUDED.location;
SELECT * FROM departments WHERE dept_name = 'Sales';          -- dept_id stays 2, location changed

-- ---------------------------------------------------------------
-- 3. A counter: the classic upsert use case
-- ---------------------------------------------------------------
CREATE TEMP TABLE page_views (page TEXT PRIMARY KEY, views INT NOT NULL);

INSERT INTO page_views VALUES ('/home', 1)
ON CONFLICT (page) DO UPDATE SET views = page_views.views + 1;
INSERT INTO page_views VALUES ('/home', 1)
ON CONFLICT (page) DO UPDATE SET views = page_views.views + 1;
INSERT INTO page_views VALUES ('/about', 1)
ON CONFLICT (page) DO UPDATE SET views = page_views.views + 1;

SELECT * FROM page_views;      -- /home 2, /about 1

-- ---------------------------------------------------------------
-- 4. MERGE: sync a staging table (a supplier's price list) into products
-- ---------------------------------------------------------------
CREATE TEMP TABLE price_feed (
    product_id    INT,
    product_name  VARCHAR(100),
    category      VARCHAR(50),
    price         NUMERIC(10,2),
    discontinued  BOOLEAN
);

INSERT INTO price_feed VALUES
    (1,  'Laptop Pro 14', 'Electronics', 82000, false),   -- price change
    (8,  'Gel Pen Set',   'Stationery',    150, false),   -- unchanged
    (10, 'Desk Lamp',     'Furniture',    1800, true),    -- discontinued → delete
    (12, 'Monitor Arm',   'Furniture',    3200, false);   -- new product

MERGE INTO products p
USING price_feed f
ON p.product_id = f.product_id
WHEN MATCHED AND f.discontinued THEN
    DELETE
WHEN MATCHED AND p.price <> f.price THEN
    UPDATE SET price = f.price
WHEN NOT MATCHED AND NOT f.discontinued THEN
    INSERT (product_id, product_name, category, price, stock)
    VALUES (f.product_id, f.product_name, f.category, f.price, 0);

SELECT product_id, product_name, price FROM products WHERE product_id IN (1, 8, 10, 12) ORDER BY product_id;

-- ---------------------------------------------------------------
-- 5. Why check-then-insert is unsafe (described, since it needs two sessions):
--    Session A: SELECT ... WHERE page = '/x';   -- not found
--    Session B: SELECT ... WHERE page = '/x';   -- not found
--    Session A: INSERT '/x'                     -- ok
--    Session B: INSERT '/x'                     -- duplicate key error (or a duplicate row with no constraint)
--    INSERT ... ON CONFLICT handles this race atomically.
-- ---------------------------------------------------------------
