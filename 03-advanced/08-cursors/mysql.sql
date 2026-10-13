-- 08 · Cursors in MySQL (only inside stored programs)
-- Run with the mysql command-line client.

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    emp_id      INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50),
    department  VARCHAR(50),
    salary      INT
);

INSERT INTO employees (name, department, salary) VALUES
    ('Alice', 'IT', 60000), ('Bob', 'HR', 45000), ('Charlie', 'IT', 70000);

DROP PROCEDURE IF EXISTS ListHighEarners;

DELIMITER //
CREATE PROCEDURE ListHighEarners(IN p_min INT)
BEGIN
    -- Order matters: variables, then cursors, then handlers
    DECLARE v_name   VARCHAR(50);
    DECLARE v_salary INT;
    DECLARE done     INT DEFAULT 0;
    DECLARE v_result TEXT DEFAULT '';

    DECLARE c CURSOR FOR
        SELECT name, salary FROM employees WHERE salary >= p_min ORDER BY salary DESC;

    -- When FETCH finds no more rows, set done = 1 instead of raising an error
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN c;
    read_loop: LOOP
        FETCH c INTO v_name, v_salary;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        SET v_result = CONCAT(v_result, v_name, '=', v_salary, '; ');
    END LOOP;
    CLOSE c;

    SELECT v_result AS high_earners;
END //
DELIMITER ;

CALL ListHighEarners(50000);    -- Charlie=70000; Alice=60000;

DROP PROCEDURE ListHighEarners;
DROP TABLE employees;
