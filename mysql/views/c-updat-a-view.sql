CREATE OR REPLACE VIEW customer_orders AS
SELECT c.name, o.product
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id;