


drop table employees


-- Employees table
CREATE TABLE employees (
    emp_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    salary INT
);


-- Log table (to store changes)

CREATE TABLE employee_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_type VARCHAR(50),
    emp_name VARCHAR(50),
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);




-- AFTER INSERT Trigger

-- This trigger logs when a new employee is added.

DELIMITER //

CREATE TRIGGER after_employee_insert
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO employee_log(action_type, emp_name)
    VALUES ('INSERT', NEW.name);
END 

//

DELIMITER ;

-- Explanation:
-- 
-- NEW refers to new row values
-- 
-- Runs after insert



-- Insert Data
INSERT INTO employees (name, salary)
VALUES ('Alice', 60000);

Automatically adds a record to employee_log.

SELECT * from employee_log


