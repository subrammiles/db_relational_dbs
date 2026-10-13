-- 04 · SELECT and WHERE (PostgreSQL)

-- Every column, every row
SELECT * FROM departments;

-- Chosen columns
SELECT first_name, last_name, job_title FROM employees;

-- Expressions and aliases
SELECT first_name || ' ' || last_name AS full_name,
       salary,
       salary * 12           AS annual_salary,
       salary * 0.10         AS bonus
FROM employees;

-- SELECT without FROM (not allowed in Oracle: use FROM dual there)
SELECT 2 + 3 AS answer, CURRENT_DATE AS today;

-- WHERE with comparison operators
SELECT first_name, salary FROM employees WHERE salary > 100000;
SELECT first_name, job_title FROM employees WHERE job_title = 'Engineer';
SELECT first_name, dept_id FROM employees WHERE dept_id <> 1;
SELECT name, signup_date FROM customers WHERE signup_date >= '2025-01-01';

-- Text comparison is case-sensitive in PostgreSQL: this returns nothing
SELECT * FROM departments WHERE dept_name = 'engineering';
-- ...so compare in one case
SELECT * FROM departments WHERE LOWER(dept_name) = 'engineering';

-- NULL is not equal to anything, not even NULL
SELECT first_name FROM employees WHERE email = NULL;      -- 0 rows!
SELECT first_name FROM employees WHERE email IS NULL;     -- Tom

-- An alias can't be used in WHERE (it is evaluated before SELECT):
-- SELECT salary * 12 AS annual FROM employees WHERE annual > 1000000;   -- ERROR: column "annual" does not exist
SELECT first_name, salary * 12 AS annual
FROM employees
WHERE salary * 12 > 1000000;
