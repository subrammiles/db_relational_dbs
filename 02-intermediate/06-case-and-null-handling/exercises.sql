-- 06 · Exercises with solutions

-- 1. Label each product 'Out of stock' (0), 'Low' (< 30) or 'OK'.
SELECT product_name, stock,
       CASE WHEN stock = 0 THEN 'Out of stock'
            WHEN stock < 30 THEN 'Low'
            ELSE 'OK' END AS stock_level
FROM products;

-- 2. Number of products per price tier: Budget (< 1000), Mid (< 20000), Premium.
SELECT CASE WHEN price < 1000  THEN 'Budget'
            WHEN price < 20000 THEN 'Mid'
            ELSE 'Premium' END AS tier,
       COUNT(*) AS products
FROM products
GROUP BY 1;

-- 3. For each customer, number of delivered and not-delivered orders in two columns.
SELECT customer_id,
       COUNT(CASE WHEN status = 'delivered' THEN 1 END)  AS delivered,
       COUNT(CASE WHEN status <> 'delivered' THEN 1 END) AS not_delivered
FROM orders
GROUP BY customer_id
ORDER BY customer_id;

-- 4. Customer contact: email if present, otherwise the text 'call: ' followed by the city.
SELECT name, COALESCE(email, 'call: ' || city) AS contact FROM customers;

-- 5. Average order value per customer that returns NULL (not an error) for a customer with 0 orders.
SELECT c.name,
       SUM(oi.quantity * oi.unit_price) / NULLIF(COUNT(DISTINCT o.order_id), 0) AS avg_order_value
FROM customers c
LEFT JOIN orders o       ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id   = o.order_id
GROUP BY c.customer_id, c.name
ORDER BY c.customer_id;
