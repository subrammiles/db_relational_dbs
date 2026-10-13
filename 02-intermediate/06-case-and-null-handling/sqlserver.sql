-- 06 · CASE, IIF, ISNULL and friends in SQL Server (T-SQL)

-- CASE works as in standard SQL
SELECT first_name, salary,
       CASE WHEN salary >= 150000 THEN 'High' WHEN salary >= 80000 THEN 'Medium' ELSE 'Low' END AS band
FROM employees;

-- IIF(condition, if_true, if_false): shorthand for a two-branch CASE
SELECT order_id, IIF(status = 'delivered', 'Done', 'Open') AS label FROM orders;

-- CHOOSE(index, v1, v2, ...): pick by position
SELECT CHOOSE(2, 'low', 'medium', 'high') AS second_choice;

-- ISNULL (2 args, T-SQL) vs COALESCE (standard, N args)
SELECT first_name,
       ISNULL(email, 'no email')                AS isnull_email,
       COALESCE(email, 'no email')              AS coalesce_email
FROM employees
WHERE email IS NULL;

-- Gotcha: ISNULL takes the type of its FIRST argument, so the replacement can be truncated
DECLARE @code VARCHAR(2) = NULL;
SELECT ISNULL(@code, 'unknown') AS isnull_result,      -- 'un'
       COALESCE(@code, 'unknown') AS coalesce_result;  -- 'unknown'

-- NULLIF to avoid divide-by-zero
SELECT product_name, price / NULLIF(stock, 0) AS price_per_unit FROM products;

-- + concatenation propagates NULL; CONCAT treats NULL as ''
SELECT 'a' + NULL AS plus_result, CONCAT('a', NULL) AS concat_result;

-- Conditional aggregation (no FILTER clause in SQL Server)
SELECT SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) AS delivered,
       COUNT(CASE WHEN status = 'cancelled' THEN 1 END)      AS cancelled
FROM orders;
