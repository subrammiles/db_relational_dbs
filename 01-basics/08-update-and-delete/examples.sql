-- 08 · UPDATE and DELETE (PostgreSQL)
-- Everything here runs inside a transaction that is rolled back at the end,
-- so the sample data is unchanged afterwards.

BEGIN;

-- 1. Preview, then update one row
SELECT emp_id, first_name, email FROM employees WHERE emp_id = 16;
UPDATE employees SET email = 'tom.wilson@corp.com' WHERE emp_id = 16;

-- 2. Several columns at once, using the current value
UPDATE employees
SET salary = salary * 1.10,
    job_title = 'Senior Sales Executive'
WHERE emp_id = 9
RETURNING emp_id, first_name, job_title, salary;

-- 3. Many rows: 5% raise for all of Sales
UPDATE employees SET salary = salary * 1.05 WHERE dept_id = 2;

-- 4. Update based on another table (PostgreSQL UPDATE ... FROM):
--    restock every product that appears in a pending order
UPDATE products p
SET stock = p.stock + 10
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE oi.product_id = p.product_id
  AND o.status = 'pending';

-- Same thing in standard SQL with a subquery (works in Oracle too)
UPDATE products
SET stock = stock + 10
WHERE product_id IN (
    SELECT oi.product_id
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status = 'pending'
);

-- 5. Correlated update: set each product's price to the highest price it was ever sold at
UPDATE products p
SET price = (SELECT MAX(oi.unit_price) FROM order_items oi WHERE oi.product_id = p.product_id)
WHERE EXISTS (SELECT 1 FROM order_items oi WHERE oi.product_id = p.product_id);

-- 6. Delete one row and see what was deleted
DELETE FROM orders WHERE order_id = 18 RETURNING *;     -- its order_items go too (ON DELETE CASCADE)

-- 7. Delete with a condition on another table (PostgreSQL DELETE ... USING)
DELETE FROM order_items oi
USING orders o
WHERE o.order_id = oi.order_id
  AND o.status = 'cancelled';

-- 8. A foreign key stops you deleting a referenced parent:
-- DELETE FROM departments WHERE dept_id = 1;
-- ERROR: update or delete on table "departments" violates foreign key constraint ... on table "employees"
DELETE FROM departments WHERE dept_id = 6;              -- Research has no employees, so this works

-- 9. Swap two columns: both SET expressions see the OLD values
CREATE TEMP TABLE pair (a INT, b INT);
INSERT INTO pair VALUES (1, 2);
UPDATE pair SET a = b, b = a;
SELECT * FROM pair;                                      -- a=2, b=1

ROLLBACK;   -- undo everything above

SELECT COUNT(*) AS orders_still_there FROM orders;      -- 18
