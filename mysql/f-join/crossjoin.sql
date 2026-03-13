CROSS JOIN

Produces all combinations of rows.

SELECT customers.name, orders.product
FROM customers
CROSS JOIN orders;

If:

customers = 4

orders = 4

Result = 16 rows.

Used rarely.