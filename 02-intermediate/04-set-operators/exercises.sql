-- 04 · Exercises with solutions

-- 1. Product ids that were never ordered, using a set operator.
SELECT product_id FROM products
EXCEPT
SELECT product_id FROM order_items;

-- 2. Customers who ordered in both 2025 and 2026.
SELECT customer_id FROM orders WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01'
INTERSECT
SELECT customer_id FROM orders WHERE order_date >= '2026-01-01' AND order_date < '2027-01-01';

-- 3. One list of every person's email (employees and customers), without duplicates and without NULLs.
SELECT email FROM employees WHERE email IS NOT NULL
UNION
SELECT email FROM customers WHERE email IS NOT NULL
ORDER BY email;

-- 4. A report with one row per order status plus a final 'TOTAL' row.
SELECT status, COUNT(*) AS orders FROM orders GROUP BY status
UNION ALL
SELECT 'TOTAL', COUNT(*) FROM orders;
