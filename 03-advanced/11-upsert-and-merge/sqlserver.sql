-- 11 · Upsert in SQL Server (T-SQL)

BEGIN TRANSACTION;

-- MERGE: sync a source set into a target (must end with ';')
CREATE TABLE #price_feed (product_id INT, product_name VARCHAR(100), category VARCHAR(50), price DECIMAL(10,2), discontinued BIT);
INSERT INTO #price_feed VALUES
    (1,  'Laptop Pro 14', 'Electronics', 82000, 0),
    (10, 'Desk Lamp',     'Furniture',    1800, 1),
    (12, 'Monitor Arm',   'Furniture',    3200, 0);

MERGE products AS p
USING #price_feed AS f
   ON p.product_id = f.product_id
WHEN MATCHED AND f.discontinued = 1 THEN
    DELETE
WHEN MATCHED AND p.price <> f.price THEN
    UPDATE SET price = f.price
WHEN NOT MATCHED BY TARGET AND f.discontinued = 0 THEN
    INSERT (product_id, product_name, category, price, stock)
    VALUES (f.product_id, f.product_name, f.category, f.price, 0)
OUTPUT $action AS action, inserted.product_id AS new_id, deleted.product_id AS old_id;

-- MERGE has had concurrency bugs and races; for single-row upserts many teams prefer
-- UPDATE-then-INSERT inside a transaction with UPDLOCK + SERIALIZABLE (HOLDLOCK):
DECLARE @page VARCHAR(100) = '/home';
CREATE TABLE #page_views (page VARCHAR(100) PRIMARY KEY, views INT NOT NULL);

UPDATE #page_views WITH (UPDLOCK, SERIALIZABLE) SET views = views + 1 WHERE page = @page;
IF @@ROWCOUNT = 0
    INSERT INTO #page_views (page, views) VALUES (@page, 1);

UPDATE #page_views WITH (UPDLOCK, SERIALIZABLE) SET views = views + 1 WHERE page = @page;
IF @@ROWCOUNT = 0
    INSERT INTO #page_views (page, views) VALUES (@page, 1);

SELECT * FROM #page_views;     -- /home 2

ROLLBACK;
