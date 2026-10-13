-- 02 · Exercises with solutions

-- 1. Number of products and average price per category.
SELECT category, COUNT(*) AS products, ROUND(AVG(price), 2) AS avg_price
FROM products
GROUP BY category;

-- 2. Number of customers per country, biggest first.
SELECT country, COUNT(*) AS customers
FROM customers
GROUP BY country
ORDER BY customers DESC, country;

-- 3. Orders per month in 2025.
SELECT DATE_TRUNC('month', order_date)::DATE AS month, COUNT(*) AS orders
FROM orders
WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

-- 4. Orders whose total value is over 50000.
SELECT order_id, SUM(quantity * unit_price) AS order_total
FROM order_items
GROUP BY order_id
HAVING SUM(quantity * unit_price) > 50000
ORDER BY order_total DESC;

-- 5. Managers (manager_id) with more than 2 direct reports.
SELECT manager_id, COUNT(*) AS direct_reports
FROM employees
WHERE manager_id IS NOT NULL
GROUP BY manager_id
HAVING COUNT(*) > 2;

-- 6. Categories where every product costs at least 1000.
SELECT category FROM products
GROUP BY category
HAVING MIN(price) >= 1000;
