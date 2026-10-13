-- 05 · Exercises with solutions

-- 1. Products priced above the average product price.
SELECT product_name, price FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- 2. Customers who have never placed an order (use NOT EXISTS).
SELECT name FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- 3. The most expensive product in each category (correlated subquery).
SELECT category, product_name, price FROM products p
WHERE price = (SELECT MAX(price) FROM products p2 WHERE p2.category = p.category)
ORDER BY category;

-- 4. Employees who were hired before their own manager.
SELECT e.first_name, e.hire_date
FROM employees e
WHERE e.hire_date < (SELECT m.hire_date FROM employees m WHERE m.emp_id = e.manager_id);

-- 5. The customer(s) with the highest total spend.
SELECT c.name, t.total
FROM customers c
JOIN (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS total
    FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id
) t ON t.customer_id = c.customer_id
WHERE t.total = (
    SELECT MAX(total) FROM (
        SELECT SUM(oi.quantity * oi.unit_price) AS total
        FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
        GROUP BY o.customer_id
    ) x
);

-- 6. Orders containing at least one Electronics product.
SELECT order_id FROM orders o
WHERE EXISTS (
    SELECT 1 FROM order_items oi JOIN products p ON p.product_id = oi.product_id
    WHERE oi.order_id = o.order_id AND p.category = 'Electronics'
)
ORDER BY order_id;

-- 7. For each department, its single highest-paid employee, using LATERAL
--    (include departments with no employees, showing NULL).
SELECT d.dept_name, top.first_name, top.salary
FROM departments d
LEFT JOIN LATERAL (
    SELECT e.first_name, e.salary
    FROM employees e
    WHERE e.dept_id = d.dept_id
    ORDER BY e.salary DESC
    LIMIT 1
) top ON true
ORDER BY d.dept_id;

-- 8. For each product category, the 2 best-selling products by units, using LATERAL.
SELECT c.category, t.product_name, t.units
FROM (SELECT DISTINCT category FROM products) c
CROSS JOIN LATERAL (
    SELECT p.product_name, SUM(oi.quantity) AS units
    FROM products p
    JOIN order_items oi ON oi.product_id = p.product_id
    WHERE p.category = c.category
    GROUP BY p.product_name
    ORDER BY units DESC
    LIMIT 2
) t
ORDER BY c.category, t.units DESC;
