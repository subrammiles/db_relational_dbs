CREATE VIEW customer_orders AS
SELECT c.name, c.city, o.product, o.amount
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id;


SELECT * FROM customer_orders;