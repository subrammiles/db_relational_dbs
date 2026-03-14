CREATE TABLE employees (
    emp_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    department VARCHAR(50),
    salary INT,
    city VARCHAR(50)
);


INSERT INTO employees (name, department, salary, city)
VALUES
('Alice','IT',60000,'Bangalore'),
('Bob','HR',45000,'Delhi'),
('Charlie','IT',70000,'Mumbai'),
('David','Sales',50000,'Bangalore'),
('Eva','HR',55000,'Delhi');

SELECT * FROM employees WHERE name = 'Eva';

-- If no index exists on name, the database will:

-- Check row 1 → Alice ❌

-- Check row 2 → Bob ❌

-- Check row 3 → Charlie ❌
-- Check row 4 → David ❌

-- Check row 5 → Eva ✅

-- This is called a Full Table Scan.


EXPLAIN SELECT * FROM employees WHERE name = 'Eva';
Result usually shows:

type: ALL

Meaning:
Full Table Scan


#
CREATE INDEX idx_department
ON employees(department);

EXPLAIN SELECT * FROM employees WHERE name = 'Eva';
Result usually shows:

type: ref
