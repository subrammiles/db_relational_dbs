-- RIGHT JOIN

-- Returns:

-- all rows from right table

-- matching rows from left table

SELECT customers.name, orders.product
FROM customers
RIGHT JOIN orders
ON customers.customer_id = orders.customer_id;