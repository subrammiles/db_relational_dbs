-- 03 · Exercises with solutions

-- 1. Add a new department 7 called 'Legal' located in Pune.
INSERT INTO departments (dept_id, dept_name, location) VALUES (7, 'Legal', 'Pune');

-- 2. Add two employees to Legal in one statement, both reporting to Asha (emp_id 1).
INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, job_title, salary, hire_date) VALUES
    (17, 'Kavya', 'Reddy', 'kavya.reddy@corp.com', 7, 1, 'Legal Counsel', 120000, '2026-01-05'),
    (18, 'Imran', 'Khan',  'imran.khan@corp.com',  7, 17, 'Paralegal',     60000, '2026-02-01');

-- 3. Create table `uk_customers (customer_id, name)` and fill it with every customer from the UK.
DROP TABLE IF EXISTS uk_customers;
CREATE TABLE uk_customers (customer_id INT PRIMARY KEY, name VARCHAR(100));
INSERT INTO uk_customers (customer_id, name)
SELECT customer_id, name FROM customers WHERE country = 'UK';

SELECT * FROM uk_customers;
DROP TABLE uk_customers;
