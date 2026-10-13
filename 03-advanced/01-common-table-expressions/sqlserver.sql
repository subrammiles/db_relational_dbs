-- 01 · CTEs and recursion in SQL Server (T-SQL)
-- No RECURSIVE keyword. The statement before WITH must end with ';'.

-- Org chart
WITH org AS (
    SELECT emp_id, first_name, manager_id, 1 AS level,
           CAST(first_name AS VARCHAR(200)) AS path         -- recursive columns need matching types
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.first_name, e.manager_id, o.level + 1,
           CAST(o.path + ' > ' + e.first_name AS VARCHAR(200))
    FROM employees e
    JOIN org o ON e.manager_id = o.emp_id
)
SELECT REPLICATE('    ', level - 1) + first_name AS org_chart, level, path
FROM org
ORDER BY path;

-- Recursion depth is limited to 100 by default; raise it (0 = unlimited) with a hint
WITH nums AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 365
)
SELECT COUNT(*) AS days FROM nums
OPTION (MAXRECURSION 400);

-- Generating a series without recursion (2022+)
SELECT value AS n FROM GENERATE_SERIES(1, 5);

-- CTE feeding an UPDATE (rolled back)
BEGIN TRANSACTION;
WITH low_paid AS (
    SELECT emp_id, salary FROM employees WHERE salary < 70000
)
UPDATE low_paid SET salary = salary + 5000;
SELECT first_name, salary FROM employees WHERE salary < 75000;
ROLLBACK;
