-- 01 · Exercises with solutions

-- 1. How many products are there, and what is their average price?
SELECT COUNT(*) AS products, ROUND(AVG(price), 2) AS avg_price FROM products;

-- 2. Total units in stock across all products.
SELECT SUM(stock) AS total_units FROM products;

-- 3. The earliest and latest order dates.
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order FROM orders;

-- 4. How many customers have an email, and how many don't?
SELECT COUNT(email)            AS with_email,
       COUNT(*) - COUNT(email) AS without_email
FROM customers;

-- 5. Revenue from delivered orders only. (Needs a join: see lesson 03 if this is new.)
SELECT SUM(oi.quantity * oi.unit_price) AS delivered_revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'delivered';

-- 6. The cheapest product's name and price (including ties).
SELECT product_name, price FROM products
WHERE price = (SELECT MIN(price) FROM products);
