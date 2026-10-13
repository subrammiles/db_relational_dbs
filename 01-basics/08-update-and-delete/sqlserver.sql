-- 08 · UPDATE and DELETE in SQL Server (T-SQL)
-- Wrapped in a transaction and rolled back, so the sample data is unchanged.

BEGIN TRANSACTION;

-- OUTPUT shows old (deleted.*) and new (inserted.*) values
UPDATE employees
SET salary = salary * 1.10
OUTPUT inserted.emp_id, deleted.salary AS old_salary, inserted.salary AS new_salary
WHERE dept_id = 3;

-- UPDATE with a join: UPDATE alias ... FROM ... JOIN
UPDATE p
SET p.stock = p.stock + 10
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o       ON o.order_id    = oi.order_id
WHERE o.status = 'pending';

-- DELETE with a join: DELETE alias FROM ... JOIN
DELETE oi
OUTPUT deleted.*
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'cancelled';

-- TOP limits how many rows a DML statement touches (batching large deletes)
DELETE TOP (2) FROM order_items WHERE order_id = 1;

-- @@ROWCOUNT: rows affected by the previous statement
UPDATE customers SET email = 'emma@mail.com' WHERE customer_id = 6;
SELECT @@ROWCOUNT AS rows_updated;

-- In SQL Server, TRUNCATE can be rolled back inside a transaction
SELECT * INTO #copy FROM products;
TRUNCATE TABLE #copy;
SELECT COUNT(*) AS after_truncate FROM #copy;

ROLLBACK TRANSACTION;

SELECT COUNT(*) AS order_items_still_there FROM order_items;    -- 25
