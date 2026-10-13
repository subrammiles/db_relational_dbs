-- 03 · Exercises with solutions

-- 1. Create a view `product_sales` with product name, category, units sold and revenue
--    (products never sold should show 0).
CREATE OR REPLACE VIEW product_sales AS
SELECT p.product_id, p.product_name, p.category,
       COALESCE(SUM(oi.quantity), 0)                AS units_sold,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS revenue
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.category;

-- 2. Use the view: best-selling category by revenue.
SELECT category, SUM(revenue) AS revenue
FROM product_sales
GROUP BY category
ORDER BY revenue DESC
LIMIT 1;

-- 3. Create an updatable view `pending_orders` (only pending orders) that refuses to
--    insert/update rows that aren't pending.
CREATE OR REPLACE VIEW pending_orders AS
SELECT order_id, customer_id, order_date, status
FROM orders
WHERE status = 'pending'
WITH CHECK OPTION;

BEGIN;
INSERT INTO pending_orders VALUES (20, 9, '2026-04-01', 'pending');   -- allowed
SELECT * FROM pending_orders;
ROLLBACK;

-- 4. Create a materialized view of revenue per country and refresh it.
CREATE MATERIALIZED VIEW country_revenue AS
SELECT c.country, SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
GROUP BY c.country;
REFRESH MATERIALIZED VIEW country_revenue;
SELECT * FROM country_revenue ORDER BY revenue DESC;

DROP MATERIALIZED VIEW country_revenue;
DROP VIEW pending_orders;
DROP VIEW product_sales;
