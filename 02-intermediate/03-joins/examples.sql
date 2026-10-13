-- 03 · Joins on the sample database (PostgreSQL)

-- INNER JOIN: employees with their department (Tom has none, so he's missing: 15 rows)
SELECT e.first_name, e.last_name, d.dept_name
FROM employees e
INNER JOIN departments d ON d.dept_id = e.dept_id
ORDER BY d.dept_name, e.first_name;

-- LEFT JOIN: every employee, department if any (Tom shows with NULL: 16 rows)
SELECT e.first_name, d.dept_name
FROM employees e
LEFT JOIN departments d ON d.dept_id = e.dept_id
ORDER BY e.emp_id;

-- RIGHT JOIN: every department, employees if any (Research shows with NULL)
SELECT d.dept_name, e.first_name
FROM employees e
RIGHT JOIN departments d ON d.dept_id = e.dept_id
ORDER BY d.dept_id;

-- FULL JOIN: both Tom and Research appear
SELECT e.first_name, d.dept_name
FROM employees e
FULL JOIN departments d ON d.dept_id = e.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;     -- show only the unmatched ones

-- Self join: each employee and their manager (LEFT so the CEO is included)
SELECT e.first_name AS employee, m.first_name AS manager
FROM employees e
LEFT JOIN employees m ON m.emp_id = e.manager_id
ORDER BY e.emp_id;

-- Employees who earn at least 60% of their manager's salary
SELECT e.first_name, e.salary, m.first_name AS manager, m.salary AS manager_salary
FROM employees e
JOIN employees m ON m.emp_id = e.manager_id
WHERE e.salary >= m.salary * 0.6;

-- Joining four tables: what did each customer buy?
SELECT c.name, o.order_id, o.order_date, p.product_name, oi.quantity, oi.unit_price
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
JOIN products p     ON p.product_id  = oi.product_id
ORDER BY o.order_id, p.product_name;

-- Join + GROUP BY: revenue per customer
SELECT c.name, SUM(oi.quantity * oi.unit_price) AS revenue
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
WHERE o.status <> 'cancelled'
GROUP BY c.customer_id, c.name
ORDER BY revenue DESC;

-- Anti-join: customers who never ordered (Omar, Sara)
SELECT c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- Same with NOT EXISTS (usually the clearest)
SELECT c.name
FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);

-- Products never ordered (Desk Lamp)
SELECT p.product_name
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
WHERE oi.product_id IS NULL;

-- PITFALL: a WHERE on the right table turns LEFT JOIN into INNER JOIN.
-- Intended: every customer, with their delivered-order count (0 if none).
-- Wrong: customers without delivered orders vanish.
SELECT c.name, COUNT(o.order_id) AS delivered
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.status = 'delivered'
GROUP BY c.customer_id, c.name
ORDER BY c.name;

-- Right: put the condition in ON
SELECT c.name, COUNT(o.order_id) AS delivered
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'delivered'
GROUP BY c.customer_id, c.name
ORDER BY c.name;

-- PITFALL: fan-out. Each department's "budget" is counted once per employee.
-- (Here we compute it per department first, then join: correct.)
SELECT d.dept_name, s.payroll, s.headcount
FROM departments d
LEFT JOIN (
    SELECT dept_id, SUM(salary) AS payroll, COUNT(*) AS headcount
    FROM employees
    GROUP BY dept_id
) s ON s.dept_id = d.dept_id
ORDER BY d.dept_id;

-- Non-equi join: put each employee into a salary band
SELECT e.first_name, e.salary, b.band
FROM employees e
JOIN (VALUES ('Junior',      0,      70000),
             ('Mid',     70000,     120000),
             ('Senior', 120000,     200000),
             ('Exec',   200000, 1000000000)) AS b(band, low, high)
  ON e.salary >= b.low AND e.salary < b.high
ORDER BY e.salary;

-- USING: join on same-named column; dept_id appears once in SELECT *
SELECT * FROM employees JOIN departments USING (dept_id) LIMIT 3;
