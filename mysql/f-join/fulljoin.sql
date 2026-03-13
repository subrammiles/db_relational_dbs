-- FULL JOIN (Not directly supported in MySQL)

-- MySQL does not support FULL OUTER JOIN, but we can simulate it.

SELECT customers.name, orders.product
FROM customers
LEFT JOIN orders
ON customers.customer_id = orders.customer_id

UNION

SELECT customers.name, orders.product
FROM customers
RIGHT JOIN orders
ON customers.customer_id = orders.customer_id;

-- This shows all rows from both tables.