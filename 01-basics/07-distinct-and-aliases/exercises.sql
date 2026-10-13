-- 07 · Exercises with solutions

-- 1. List each product category once.
SELECT DISTINCT category FROM products ORDER BY category;

-- 2. How many different customers have placed an order?
SELECT COUNT(DISTINCT customer_id) AS customers_who_ordered FROM orders;

-- 3. List the distinct order statuses with the alias "Order Status".
SELECT DISTINCT status AS "Order Status" FROM orders;

-- 4. Show product name and list price as `item` and `list_price`, using table alias p.
SELECT p.product_name AS item, p.price AS list_price FROM products p;

-- 5. Which cities do customers come from, with country, each pair once?
SELECT DISTINCT city, country FROM customers ORDER BY country, city;
