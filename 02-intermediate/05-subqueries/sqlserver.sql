-- 05 · Subqueries and CROSS APPLY / OUTER APPLY in SQL Server (T-SQL)

-- Correlated subquery: employees above their department's average
SELECT e.first_name, e.dept_id, e.salary
FROM employees e
WHERE e.salary > (SELECT AVG(e2.salary) FROM employees e2 WHERE e2.dept_id = e.dept_id);

-- NOT EXISTS: departments with no employees
SELECT d.dept_name FROM departments d
WHERE NOT EXISTS (SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id);

-- CROSS APPLY = CROSS JOIN LATERAL: the 2 most recent orders of every customer
SELECT c.name, r.order_id, r.order_date
FROM customers c
CROSS APPLY (
    SELECT TOP (2) o.order_id, o.order_date
    FROM orders o
    WHERE o.customer_id = c.customer_id
    ORDER BY o.order_date DESC
) r
ORDER BY c.name, r.order_date DESC;

-- OUTER APPLY = LEFT JOIN LATERAL: keeps customers with no orders
SELECT c.name, r.last_order, r.spent
FROM customers c
OUTER APPLY (
    SELECT MAX(o.order_date) AS last_order, SUM(oi.quantity * oi.unit_price) AS spent
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.customer_id = c.customer_id
) r
ORDER BY r.spent DESC;

-- APPLY with a VALUES list: unpivot several columns into rows
SELECT p.product_name, v.measure, v.value
FROM products p
CROSS APPLY (VALUES ('price', p.price), ('stock', CAST(p.stock AS DECIMAL(10,2)))) AS v(measure, value)
WHERE p.product_id IN (1, 2);
