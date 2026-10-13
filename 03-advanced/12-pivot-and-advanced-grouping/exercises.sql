-- 12 · Exercises with solutions

-- 1. Number of customers per country, with a column per signup year (2024, 2025).
SELECT country,
       COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM signup_date) = 2024) AS "2024",
       COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM signup_date) = 2025) AS "2025",
       COUNT(*) AS total
FROM customers
GROUP BY country
ORDER BY total DESC, country;

-- 2. Units sold per product category per month of 2025 as a grid (Jan..Jun shown).
SELECT p.category,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 1 THEN oi.quantity ELSE 0 END) AS jan,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 2 THEN oi.quantity ELSE 0 END) AS feb,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 3 THEN oi.quantity ELSE 0 END) AS mar,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 4 THEN oi.quantity ELSE 0 END) AS apr,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 5 THEN oi.quantity ELSE 0 END) AS may,
       SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 6 THEN oi.quantity ELSE 0 END) AS jun
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.order_date >= '2025-01-01' AND o.order_date < '2026-01-01'
GROUP BY p.category;

-- 3. Payroll by location and department with location subtotals and a grand total.
SELECT COALESCE(d.location, 'ALL')  AS location,
       COALESCE(d.dept_name, 'ALL') AS dept,
       SUM(e.salary) AS payroll
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id
GROUP BY ROLLUP (d.location, d.dept_name)
ORDER BY GROUPING(d.location), d.location, GROUPING(d.dept_name), d.dept_name;
