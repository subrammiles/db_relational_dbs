-- 06 · CASE and NULL handling (PostgreSQL)

-- Searched CASE: salary bands
SELECT first_name, salary,
       CASE
           WHEN salary >= 150000 THEN 'High'
           WHEN salary >=  80000 THEN 'Medium'
           ELSE 'Low'
       END AS band
FROM employees
ORDER BY salary DESC;

-- Simple CASE: friendly status labels
SELECT order_id, status,
       CASE status
           WHEN 'delivered' THEN 'Done'
           WHEN 'cancelled' THEN 'Cancelled'
           ELSE 'In progress'
       END AS label
FROM orders;

-- CASE in GROUP BY: headcount per band
SELECT CASE WHEN salary >= 150000 THEN 'High'
            WHEN salary >=  80000 THEN 'Medium'
            ELSE 'Low' END AS band,
       COUNT(*) AS people
FROM employees
GROUP BY 1
ORDER BY people DESC;

-- Conditional aggregation: one row, a column per status (a simple pivot)
SELECT SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) AS delivered,
       SUM(CASE WHEN status = 'shipped'   THEN 1 ELSE 0 END) AS shipped,
       SUM(CASE WHEN status = 'pending'   THEN 1 ELSE 0 END) AS pending,
       SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled
FROM orders;

-- CASE in ORDER BY: custom order (pending first, then shipped, then the rest)
SELECT order_id, status
FROM orders
ORDER BY CASE status WHEN 'pending' THEN 1 WHEN 'shipped' THEN 2 ELSE 3 END, order_id;

-- CASE in UPDATE: different raise per department (rolled back)
BEGIN;
UPDATE employees
SET salary = salary * CASE dept_id
                          WHEN 1 THEN 1.10
                          WHEN 2 THEN 1.08
                          ELSE 1.05
                      END;
ROLLBACK;

-- ---------------------------------------------------------------
-- NULL behaviour
-- ---------------------------------------------------------------
SELECT NULL = NULL          AS null_equals_null,   -- NULL (unknown)
       NULL IS NULL         AS is_null,            -- true
       1 + NULL             AS arithmetic,         -- NULL
       'a' || NULL          AS concat_operator,    -- NULL
       CONCAT('a', NULL)    AS concat_function;    -- 'a' (CONCAT skips NULLs)

-- COALESCE: first non-NULL value
SELECT first_name, COALESCE(email, 'no email') AS email,
       COALESCE(dept_id::TEXT, 'unassigned')   AS dept
FROM employees
WHERE email IS NULL OR dept_id IS NULL;

-- NULLIF: turn a value into NULL, mostly to avoid division by zero
SELECT product_name, price, stock,
       ROUND(price / NULLIF(stock, 0), 2) AS price_per_unit_in_stock    -- Desk Lamp: NULL, not an error
FROM products;
-- SELECT 1 / 0;   -- ERROR: division by zero

-- IS DISTINCT FROM: NULL-safe comparison
SELECT a, b, a = b AS equals, a IS NOT DISTINCT FROM b AS null_safe_equals
FROM (VALUES (1, 1), (1, NULL), (NULL, NULL)) AS t(a, b);

-- A simple CASE can't match NULL; use a searched CASE
SELECT first_name,
       CASE dept_id WHEN NULL THEN 'never matches' ELSE 'other' END AS simple_case,
       CASE WHEN dept_id IS NULL THEN 'no department' ELSE 'has department' END AS searched_case
FROM employees
WHERE emp_id IN (1, 16);
