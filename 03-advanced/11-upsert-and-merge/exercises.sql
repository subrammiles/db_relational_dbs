-- 11 · Exercises with solutions

-- 1. Upsert customer 6 (Emma Brown) with email 'emma@mail.com'. If the customer
--    exists, only update the email; otherwise insert the full row.
INSERT INTO customers (customer_id, name, email, city, country, signup_date)
VALUES (6, 'Emma Brown', 'emma@mail.com', 'London', 'UK', '2024-06-30')
ON CONFLICT (customer_id) DO UPDATE SET email = EXCLUDED.email;

-- 2. Maintain a daily_sales summary table: running this twice must not double count.
CREATE TABLE daily_sales (day DATE PRIMARY KEY, revenue NUMERIC(12,2) NOT NULL);

INSERT INTO daily_sales (day, revenue)
SELECT o.order_date, SUM(oi.quantity * oi.unit_price)
FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_date
ON CONFLICT (day) DO UPDATE SET revenue = EXCLUDED.revenue;    -- overwrite, don't add

-- run again: same result
INSERT INTO daily_sales (day, revenue)
SELECT o.order_date, SUM(oi.quantity * oi.unit_price)
FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_date
ON CONFLICT (day) DO UPDATE SET revenue = EXCLUDED.revenue;

SELECT COUNT(*) AS days, SUM(revenue) AS total FROM daily_sales;

-- 3. Use MERGE to apply a stock delivery: add quantities for known products,
--    ignore unknown product ids.
CREATE TEMP TABLE delivery (product_id INT, qty INT);
INSERT INTO delivery VALUES (10, 25), (3, 10), (999, 5);

MERGE INTO products p
USING delivery d ON p.product_id = d.product_id
WHEN MATCHED THEN UPDATE SET stock = p.stock + d.qty;

SELECT product_id, stock FROM products WHERE product_id IN (3, 10);

DROP TABLE daily_sales;
