-- 03 · Exercises with solutions

-- 1. List every order with the customer's name and the order status.
SELECT o.order_id, c.name, o.status
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_id;

-- 2. List every department with its number of employees, including departments with none.
SELECT d.dept_name, COUNT(e.emp_id) AS headcount
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY headcount DESC, d.dept_name;

-- 3. Employees and the name of their manager's department.
SELECT e.first_name AS employee, m.first_name AS manager, md.dept_name AS manager_dept
FROM employees e
JOIN employees m         ON m.emp_id   = e.manager_id
LEFT JOIN departments md ON md.dept_id = m.dept_id;

-- 4. Total units sold per product category (exclude cancelled orders).
SELECT p.category, SUM(oi.quantity) AS units
FROM order_items oi
JOIN orders o   ON o.order_id   = oi.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.status <> 'cancelled'
GROUP BY p.category
ORDER BY units DESC;

-- 5. Items sold below list price: order, product, list price, price charged.
SELECT oi.order_id, p.product_name, p.price AS list_price, oi.unit_price
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
WHERE oi.unit_price < p.price;

-- 6. Customers who bought anything from the Furniture category (each once).
SELECT c.name
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p     ON p.product_id = oi.product_id
    WHERE o.customer_id = c.customer_id AND p.category = 'Furniture'
)
ORDER BY c.name;

-- 7. Pairs of employees in the same department with the same salary.
SELECT a.first_name, b.first_name, a.salary, a.dept_id
FROM employees a
JOIN employees b
  ON a.dept_id = b.dept_id
 AND a.salary  = b.salary
 AND a.emp_id  < b.emp_id;          -- "<" avoids (x,x) and listing each pair twice
