-- Returns only matching rows in both tables.

SELECT customers.name, orders.product, orders.amount
FROM customers
INNER JOIN orders
ON customers.customer_id = orders.customer_id;