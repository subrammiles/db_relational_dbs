-- 06 · Stored procedures and functions in MySQL
-- Stored procedure = a reusable SQL program stored in the database.
-- Run this file with the mysql command-line client (DELIMITER is a client command).

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    emp_id      INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50),
    department  VARCHAR(50),
    salary      INT
);

INSERT INTO employees (name, department, salary) VALUES
    ('Alice',   'IT',    60000),
    ('Bob',     'HR',    45000),
    ('Charlie', 'IT',    70000),
    ('David',   'Sales', 50000),
    ('Eva',     'HR',    55000);

DROP PROCEDURE IF EXISTS GetEmployees;
DROP PROCEDURE IF EXISTS GetByDepartment;
DROP PROCEDURE IF EXISTS DeptStats;
DROP PROCEDURE IF EXISTS GiveRaise;
DROP FUNCTION IF EXISTS AnnualSalary;

-- Change the statement delimiter so the ; inside the body doesn't end CREATE PROCEDURE
DELIMITER //

-- 1. Simplest procedure
CREATE PROCEDURE GetEmployees()
BEGIN
    SELECT * FROM employees;
END //

-- 2. IN parameter
CREATE PROCEDURE GetByDepartment(IN p_dept VARCHAR(50))
BEGIN
    SELECT name, salary FROM employees WHERE department = p_dept;
END //

-- 3. OUT parameters
CREATE PROCEDURE DeptStats(IN p_dept VARCHAR(50), OUT p_count INT, OUT p_avg DECIMAL(10,2))
BEGIN
    SELECT COUNT(*), AVG(salary) INTO p_count, p_avg
    FROM employees WHERE department = p_dept;
END //

-- 4. Validation with SIGNAL, and a transaction with an error handler
CREATE PROCEDURE GiveRaise(IN p_dept VARCHAR(50), IN p_percent DECIMAL(5,2))
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;                       -- re-raise the original error to the caller
    END;

    IF p_percent > 20 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Raise too large';
    END IF;

    START TRANSACTION;
    UPDATE employees SET salary = salary * (1 + p_percent / 100) WHERE department = p_dept;
    COMMIT;
END //

-- 5. A function: must declare DETERMINISTIC / READS SQL DATA when binary logging is on
CREATE FUNCTION AnnualSalary(p_emp_id INT) RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_salary INT;
    SELECT salary INTO v_salary FROM employees WHERE emp_id = p_emp_id;
    RETURN v_salary * 12;
END //

DELIMITER ;

-- Run them
CALL GetEmployees();
CALL GetByDepartment('IT');

CALL DeptStats('HR', @cnt, @avg);
SELECT @cnt AS hr_count, @avg AS hr_avg;

CALL GiveRaise('Sales', 10);
-- CALL GiveRaise('Sales', 50);   -- ERROR 1644 (45000): Raise too large

SELECT name, AnnualSalary(emp_id) AS annual FROM employees;

-- Inspect
SHOW PROCEDURE STATUS WHERE Db = DATABASE();
SHOW CREATE PROCEDURE GiveRaise;

DROP FUNCTION AnnualSalary;
DROP PROCEDURE GiveRaise;
DROP PROCEDURE DeptStats;
DROP PROCEDURE GetByDepartment;
DROP PROCEDURE GetEmployees;
DROP TABLE employees;
