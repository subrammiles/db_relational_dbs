-- 05 · Subqueries (PostgreSQL)

-- Scalar subquery in WHERE: who earns more than the company average?
SELECT first_name, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees)
ORDER BY salary DESC;

-- Scalar subquery in SELECT: each salary next to the average and the difference
SELECT first_name,
       salary,
       ROUND((SELECT AVG(salary) FROM employees), 0)          AS company_avg,
       ROUND(salary - (SELECT AVG(salary) FROM employees), 0) AS diff
FROM employees;

-- List subquery with IN: employees working in Bangalore
SELECT first_name, dept_id
FROM employees
WHERE dept_id IN (SELECT dept_id FROM departments WHERE location = 'Bangalore');

-- Derived table (subquery in FROM): average salary per department, then filter
SELECT d.dept_name, a.avg_salary
FROM (
    SELECT dept_id, ROUND(AVG(salary), 0) AS avg_salary
    FROM employees
    GROUP BY dept_id
) AS a
JOIN departments d ON d.dept_id = a.dept_id
WHERE a.avg_salary > 90000;

-- Correlated subquery: employees earning more than THEIR department's average
SELECT e.first_name, e.dept_id, e.salary
FROM employees e
WHERE e.salary > (
    SELECT AVG(e2.salary)
    FROM employees e2
    WHERE e2.dept_id = e.dept_id          -- refers to the outer row
);

-- Correlated subquery in SELECT: number of orders per customer
SELECT c.name,
       (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS order_count
FROM customers c
ORDER BY order_count DESC, c.name;

-- EXISTS: customers who have at least one delivered order
SELECT c.name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id AND o.status = 'delivered'
);

-- NOT EXISTS: departments with no employees (Research)
SELECT d.dept_name
FROM departments d
WHERE NOT EXISTS (SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id);

-- The NOT IN trap: employees.dept_id contains a NULL (Tom), so this returns NOTHING
SELECT dept_name FROM departments
WHERE dept_id NOT IN (SELECT dept_id FROM employees);

-- Fix 1: exclude NULLs inside the subquery
SELECT dept_name FROM departments
WHERE dept_id NOT IN (SELECT dept_id FROM employees WHERE dept_id IS NOT NULL);

-- ANY / ALL
-- Products more expensive than at least one Furniture item (> the cheapest furniture)
SELECT product_name, price FROM products
WHERE price > ANY (SELECT price FROM products WHERE category = 'Furniture')
  AND category <> 'Furniture';

-- Products more expensive than every Furniture item (> the most expensive furniture)
SELECT product_name, price FROM products
WHERE price > ALL (SELECT price FROM products WHERE category = 'Furniture');

-- Second highest salary
SELECT MAX(salary) AS second_highest
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Subquery in UPDATE (inside a transaction, rolled back)
BEGIN;
UPDATE employees
SET salary = salary * 1.05
WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name = 'HR');
ROLLBACK;

-- Most recent order per customer (correlated, compares to the max date of the same customer)
SELECT o.customer_id, o.order_id, o.order_date
FROM orders o
WHERE o.order_date = (
    SELECT MAX(o2.order_date) FROM orders o2 WHERE o2.customer_id = o.customer_id
)
ORDER BY o.customer_id;

-- ERROR if a scalar subquery returns more than one row:
-- SELECT first_name FROM employees WHERE dept_id = (SELECT dept_id FROM departments);
-- ERROR: more than one row returned by a subquery used as an expression
