Create procedure:

DELIMITER //

CREATE PROCEDURE GetEmployees()
BEGIN
SELECT * FROM employees;
END //

DELIMITER ;

Run it:

CALL GetEmployees();