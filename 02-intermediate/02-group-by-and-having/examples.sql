-- 02 · GROUP BY and HAVING (PostgreSQL)

-- Headcount and salary statistics per department (NULL = Tom, no department)
SELECT dept_id,
       COUNT(*)              AS headcount,
       SUM(salary)           AS payroll,
       ROUND(AVG(salary), 0) AS avg_salary,
       MAX(salary)           AS top_salary
FROM employees
GROUP BY dept_id
ORDER BY dept_id;

-- Group by two columns
SELECT dept_id, job_title, COUNT(*) AS people
FROM employees
GROUP BY dept_id, job_title
ORDER BY dept_id, people DESC;

-- Group by an expression: hires per year
SELECT EXTRACT(YEAR FROM hire_date) AS hire_year, COUNT(*) AS hires
FROM employees
GROUP BY EXTRACT(YEAR FROM hire_date)
ORDER BY hire_year;

-- Orders per status
SELECT status, COUNT(*) AS orders
FROM orders
GROUP BY status
ORDER BY orders DESC;

-- Revenue per product
SELECT product_id,
       SUM(quantity)              AS units_sold,
       SUM(quantity * unit_price) AS revenue
FROM order_items
GROUP BY product_id
ORDER BY revenue DESC;

-- HAVING: departments with at least 3 people
SELECT dept_id, COUNT(*) AS headcount
FROM employees
GROUP BY dept_id
HAVING COUNT(*) >= 3;

-- WHERE and HAVING together:
-- among employees earning > 60000, departments that still have 2+ such people
SELECT dept_id, COUNT(*) AS well_paid
FROM employees
WHERE salary > 60000
GROUP BY dept_id
HAVING COUNT(*) >= 2
ORDER BY well_paid DESC;

-- Customers who placed more than 2 orders
SELECT customer_id, COUNT(*) AS orders
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 2;

-- Departments whose average salary is above the company average
SELECT dept_id, ROUND(AVG(salary), 0) AS avg_salary
FROM employees
GROUP BY dept_id
HAVING AVG(salary) > (SELECT AVG(salary) FROM employees);

-- Find duplicates: salaries shared by more than one employee
SELECT salary, COUNT(*) AS how_many, STRING_AGG(first_name, ', ') AS who
FROM employees
GROUP BY salary
HAVING COUNT(*) > 1;

-- HAVING without GROUP BY: whole table is one group (returns 1 row, or none)
SELECT COUNT(*) AS products FROM products HAVING COUNT(*) > 5;

-- ERROR: column "employees.first_name" must appear in the GROUP BY clause ...
-- SELECT dept_id, first_name, COUNT(*) FROM employees GROUP BY dept_id;
