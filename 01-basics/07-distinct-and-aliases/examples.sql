-- 07 · DISTINCT and aliases (PostgreSQL)

-- Without DISTINCT: one row per customer, duplicates included
SELECT country FROM customers;

-- With DISTINCT: each country once
SELECT DISTINCT country FROM customers ORDER BY country;

-- DISTINCT over several columns = unique combinations
SELECT DISTINCT dept_id, job_title FROM employees ORDER BY dept_id, job_title;

-- Counting
SELECT COUNT(*)                AS customers,
       COUNT(DISTINCT country) AS countries,
       COUNT(DISTINCT city)    AS cities
FROM customers;

-- Which customers have ordered at least once (each listed once)
SELECT DISTINCT customer_id FROM orders ORDER BY customer_id;

-- PostgreSQL DISTINCT ON: the highest-paid employee in each department
SELECT DISTINCT ON (dept_id) dept_id, first_name, salary
FROM employees
ORDER BY dept_id, salary DESC;

-- Column aliases
SELECT emp_id               AS employee_no,
       first_name || ' ' || last_name AS "Full Name",
       salary * 12          AS annual_salary
FROM employees
ORDER BY annual_salary DESC;     -- alias allowed in ORDER BY

-- Table aliases
SELECT e.first_name, e.job_title, d.dept_name
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id;

-- Table aliases are required when a table appears twice (self-join)
SELECT e.first_name AS employee, m.first_name AS manager
FROM employees e
JOIN employees m ON m.emp_id = e.manager_id;
