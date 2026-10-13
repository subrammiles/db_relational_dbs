-- 07 · Triggers in MySQL
--
-- A trigger is SQL code that runs automatically when INSERT, UPDATE or DELETE
-- happens on a table. Triggers help automate logging, validation and audit tables.
--
--   BEFORE INSERT  runs before a new row is inserted
--   AFTER INSERT   runs after a row is inserted
--   BEFORE UPDATE  runs before an update
--   AFTER UPDATE   runs after an update
--   BEFORE DELETE  runs before a delete
--   AFTER DELETE   runs after a delete
--
-- Run with the mysql command-line client (DELIMITER is a client command).

DROP TABLE IF EXISTS employee_log;
DROP TABLE IF EXISTS employees;

-- Employees table
CREATE TABLE employees (
    emp_id  INT AUTO_INCREMENT PRIMARY KEY,
    name    VARCHAR(50),
    salary  INT
);

-- Log table (stores changes)
CREATE TABLE employee_log (
    log_id       INT AUTO_INCREMENT PRIMARY KEY,
    action_type  VARCHAR(50),
    emp_name     VARCHAR(50),
    details      VARCHAR(200),
    action_time  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //

-- AFTER INSERT: log when a new employee is added. NEW refers to the new row's values.
CREATE TRIGGER after_employee_insert
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO employee_log (action_type, emp_name)
    VALUES ('INSERT', NEW.name);
END //

-- AFTER UPDATE: OLD has the values before, NEW the values after
CREATE TRIGGER after_employee_update
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    IF OLD.salary <> NEW.salary THEN
        INSERT INTO employee_log (action_type, emp_name, details)
        VALUES ('SALARY', NEW.name, CONCAT(OLD.salary, ' -> ', NEW.salary));
    END IF;
END //

-- BEFORE INSERT: validate and fix data before it is stored
CREATE TRIGGER before_employee_insert
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF NEW.salary < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary cannot be negative';
    END IF;
    SET NEW.name = TRIM(NEW.name);
END //

-- BEFORE DELETE: keep a record of who was removed
CREATE TRIGGER before_employee_delete
BEFORE DELETE ON employees
FOR EACH ROW
BEGIN
    INSERT INTO employee_log (action_type, emp_name)
    VALUES ('DELETE', OLD.name);
END //

DELIMITER ;

-- Insert data: automatically adds a record to employee_log
INSERT INTO employees (name, salary) VALUES ('  Alice  ', 60000);
UPDATE employees SET salary = 65000 WHERE name = 'Alice';
DELETE FROM employees WHERE name = 'Alice';
-- INSERT INTO employees (name, salary) VALUES ('Bad', -1);   -- ERROR 1644 (45000): Salary cannot be negative

SELECT * FROM employee_log;

SHOW TRIGGERS;

DROP TRIGGER after_employee_insert;
DROP TRIGGER after_employee_update;
DROP TRIGGER before_employee_insert;
DROP TRIGGER before_employee_delete;
DROP TABLE employee_log;
DROP TABLE employees;
