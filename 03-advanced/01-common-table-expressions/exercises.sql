-- 01 · Exercises with solutions

-- 1. Using a CTE, list products whose total units sold is above the average units sold per product.
WITH units AS (
    SELECT product_id, SUM(quantity) AS sold
    FROM order_items
    GROUP BY product_id
)
SELECT p.product_name, u.sold
FROM units u
JOIN products p ON p.product_id = u.product_id
WHERE u.sold > (SELECT AVG(sold) FROM units)
ORDER BY u.sold DESC;

-- 2. For every manager, the number of people below them at any depth.
WITH RECURSIVE reports AS (
    SELECT manager_id AS boss, emp_id FROM employees WHERE manager_id IS NOT NULL
    UNION ALL
    SELECT r.boss, e.emp_id
    FROM reports r
    JOIN employees e ON e.manager_id = r.emp_id
)
SELECT m.first_name AS manager, COUNT(*) AS total_reports
FROM reports r
JOIN employees m ON m.emp_id = r.boss
GROUP BY m.emp_id, m.first_name
ORDER BY total_reports DESC;

-- 3. The numbers 1 to 10 and their running sum, using a recursive CTE.
WITH RECURSIVE nums AS (
    SELECT 1 AS n, 1 AS running_sum
    UNION ALL
    SELECT n + 1, running_sum + n + 1 FROM nums WHERE n < 10
)
SELECT * FROM nums;

-- 4. Every day in March 2025 with the number of orders placed that day (0 if none).
WITH RECURSIVE days AS (
    SELECT DATE '2025-03-01' AS d
    UNION ALL
    SELECT d + 1 FROM days WHERE d < DATE '2025-03-31'
)
SELECT days.d, COUNT(o.order_id) AS orders
FROM days
LEFT JOIN orders o ON o.order_date = days.d
GROUP BY days.d
ORDER BY days.d;
