-- 05 · LIKE and wildcards in MySQL

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

-- Wildcards:
--   %  any number of characters
--   _  exactly one character

-- Starts with A
SELECT * FROM employees WHERE name LIKE 'A%';

-- Ends with e
SELECT * FROM employees WHERE name LIKE '%e';

-- MySQL's default collation is case-insensitive, so this ALSO matches Alice
SELECT * FROM employees WHERE name LIKE 'a%';

-- Force a case-sensitive match
SELECT * FROM employees WHERE name LIKE BINARY 'a%';      -- 0 rows

-- Regular expression
SELECT * FROM employees WHERE name REGEXP '^[A-C]';

-- IN and BETWEEN
SELECT * FROM employees WHERE city IN ('Delhi', 'Mumbai');
SELECT * FROM employees WHERE salary BETWEEN 50000 AND 60000;

DROP TABLE employees;
