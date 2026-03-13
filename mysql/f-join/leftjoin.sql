-- LEFT JOIN

-- Returns:

-- all rows from left table

-- matching rows from right table

SELECT customers.name, orders.product
FROM customers
LEFT JOIN orders
ON customers.customer_id = orders.customer_id;