-- 02 · GROUP BY and HAVING in MySQL

CREATE TABLE employees (
    emp_id      INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50),
    department  VARCHAR(50),
    salary      INT,
    city        VARCHAR(50)
);

INSERT INTO employees (name, department, salary, city) VALUES
    ('Alice',   'IT',    60000, 'Bangalore'),
    ('Bob',     'HR',    45000, 'Delhi'),
    ('Charlie', 'IT',    70000, 'Mumbai'),
    ('David',   'Sales', 50000, 'Bangalore'),
    ('Eva',     'HR',    55000, 'Delhi');

-- GROUP BY: number of employees per department
SELECT department, COUNT(*) AS employees
FROM employees
GROUP BY department;

-- HAVING filters the groups: departments with more than 1 employee
SELECT department, COUNT(*) AS employees
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- MySQL lets you use a SELECT alias in HAVING (not portable)
SELECT department, AVG(salary) AS avg_salary
FROM employees
GROUP BY department
HAVING avg_salary > 50000;

-- GROUP_CONCAT is MySQL's string aggregation
SELECT city, GROUP_CONCAT(name ORDER BY name SEPARATOR ', ') AS people
FROM employees
GROUP BY city;

-- WITH ROLLUP adds a grand-total row (department = NULL)
SELECT department, SUM(salary) AS payroll
FROM employees
GROUP BY department WITH ROLLUP;

-- ONLY_FULL_GROUP_BY (on by default since 5.7) rejects ambiguous queries:
-- SELECT department, name, COUNT(*) FROM employees GROUP BY department;
-- ERROR 1055: Expression #2 of SELECT list is not in GROUP BY clause ...

DROP TABLE employees;
