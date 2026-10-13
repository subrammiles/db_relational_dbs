-- 07 · Exercises with solutions

-- 1. Employee initials, e.g. 'A.R.' for Asha Rao.
SELECT first_name, last_name, LEFT(first_name, 1) || '.' || LEFT(last_name, 1) || '.' AS initials
FROM employees;

-- 2. Number of customers per email domain (ignore missing emails).
SELECT SPLIT_PART(email, '@', 2) AS domain, COUNT(*) AS customers
FROM customers
WHERE email IS NOT NULL
GROUP BY 1;

-- 3. Revenue per month in 2025, with the month shown as 'Jan 2025'.
SELECT TO_CHAR(DATE_TRUNC('month', o.order_date), 'Mon YYYY') AS month,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_date >= '2025-01-01' AND o.order_date < '2026-01-01'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY DATE_TRUNC('month', o.order_date);

-- 4. Days between each customer's signup and their first order.
SELECT c.name, c.signup_date, MIN(o.order_date) AS first_order,
       MIN(o.order_date) - c.signup_date AS days_to_first_order
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name, c.signup_date
ORDER BY days_to_first_order;

-- 5. Employees with more than 8 full years of service on 2026-01-01.
SELECT first_name, hire_date
FROM employees
WHERE hire_date <= DATE '2026-01-01' - INTERVAL '8 years';

-- 6. Product names in upper case with spaces replaced by underscores (a "code").
SELECT product_name, UPPER(REPLACE(product_name, ' ', '_')) AS code FROM products;
