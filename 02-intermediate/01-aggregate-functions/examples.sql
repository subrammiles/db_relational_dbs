-- 01 · Aggregate functions (PostgreSQL)

-- One row summarising the whole table
SELECT COUNT(*)              AS employees,
       SUM(salary)           AS payroll,
       ROUND(AVG(salary), 2) AS avg_salary,
       MIN(salary)           AS lowest,
       MAX(salary)           AS highest,
       MIN(hire_date)        AS first_hire,
       MAX(last_name)        AS last_alphabetically
FROM employees;

-- COUNT(*) vs COUNT(col) vs COUNT(DISTINCT col)
SELECT COUNT(*)                AS all_rows,         -- 16
       COUNT(email)            AS with_email,       -- 15 (Tom has none)
       COUNT(dept_id)          AS with_department,  -- 15
       COUNT(DISTINCT dept_id) AS departments_used  -- 5
FROM employees;

-- Aggregates with a WHERE: only rows that pass the filter are aggregated
SELECT COUNT(*) AS delivered_orders FROM orders WHERE status = 'delivered';

-- Revenue: aggregate an expression
SELECT SUM(quantity * unit_price) AS gross_revenue FROM order_items;

-- AVG ignores NULLs
SELECT AVG(x)                AS avg_ignoring_null,  -- 150
       AVG(COALESCE(x, 0))   AS avg_null_as_zero,   -- 100
       SUM(x) / COUNT(*)     AS sum_over_all_rows   -- 100
FROM (VALUES (100), (NULL), (200)) AS t(x);

-- SUM over no rows is NULL, not 0
SELECT SUM(salary) AS sum_nothing, COALESCE(SUM(salary), 0) AS safe_sum
FROM employees WHERE dept_id = 6;

-- Conditional aggregation: several counts in one pass
SELECT COUNT(*)                                     AS total,
       COUNT(*) FILTER (WHERE status = 'delivered') AS delivered,       -- PostgreSQL / standard
       SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled  -- portable
FROM orders;

-- String aggregation
SELECT STRING_AGG(first_name, ', ' ORDER BY first_name) AS engineering_team
FROM employees WHERE dept_id = 1;

-- Median and percentiles
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary,
       PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY salary) AS p90_salary
FROM employees;

-- Who earns the most? (MAX alone can't tell you the name)
SELECT first_name, salary FROM employees
WHERE salary = (SELECT MAX(salary) FROM employees);

-- ERROR: column "employees.first_name" must appear in the GROUP BY clause or be used in an aggregate function
-- SELECT first_name, MAX(salary) FROM employees;
