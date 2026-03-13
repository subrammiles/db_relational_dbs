

-- GROUP BY

-- Group rows by column.

-- Example: number of employees per department.



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
SELECT department, COUNT(*)
FROM employees
GROUP BY department;