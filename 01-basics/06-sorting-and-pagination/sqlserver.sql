-- 06 · Sorting, TOP and pagination in SQL Server (T-SQL)

-- NULLs sort FIRST in ascending order in SQL Server (Tom has no department)
SELECT first_name, dept_id FROM employees ORDER BY dept_id;

-- No NULLS LAST keyword: sort on a CASE first
SELECT first_name, dept_id FROM employees
ORDER BY CASE WHEN dept_id IS NULL THEN 1 ELSE 0 END, dept_id;

-- TOP
SELECT TOP (3) first_name, salary FROM employees ORDER BY salary DESC;

-- TOP ... WITH TIES (8 rows: the 7th salary, 95000, is shared)
SELECT TOP (7) WITH TIES first_name, salary FROM employees ORDER BY salary DESC;

-- TOP PERCENT
SELECT TOP (25) PERCENT first_name, salary FROM employees ORDER BY salary DESC;

-- Standard pagination (2012+): ORDER BY is required
SELECT order_id, order_date FROM orders
ORDER BY order_id
OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

-- Keyset pagination
SELECT TOP (5) order_id, order_date FROM orders WHERE order_id > 10 ORDER BY order_id;

-- Old-style pagination with ROW_NUMBER (pre-2012 code)
SELECT order_id, order_date
FROM (SELECT order_id, order_date, ROW_NUMBER() OVER (ORDER BY order_id) AS rn FROM orders) t
WHERE rn BETWEEN 6 AND 10;
