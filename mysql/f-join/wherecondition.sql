-- JOIN with WHERE Condition

-- Example: customers who bought Laptop

SELECT customers.name, orders.product
FROM customers
INNER JOIN orders
ON customers.customer_id = orders.customer_id
WHERE orders.product = 'Laptop';