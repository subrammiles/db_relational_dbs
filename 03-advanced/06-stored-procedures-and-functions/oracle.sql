-- 06 · PL/SQL basics (Oracle)
--
-- PL/SQL (Procedural Language/SQL) extends SQL with variables, loops, conditions,
-- procedures, functions, packages and exception handling.
-- In SQL*Plus / SQL Developer, end each PL/SQL block with a line containing only "/".

SET SERVEROUTPUT ON;     -- show DBMS_OUTPUT.PUT_LINE output

-- ---------------------------------------------------------------
-- 1. Anonymous block: Hello World
-- ---------------------------------------------------------------
DECLARE
    message VARCHAR2(20) := 'Hello, World!';
BEGIN
    DBMS_OUTPUT.PUT_LINE(message);
END;
/

-- ---------------------------------------------------------------
-- 2. IF with SELECT INTO
-- ---------------------------------------------------------------
CREATE TABLE employee (
    emp_id     NUMBER(15)    NOT NULL,
    full_name  VARCHAR2(20)  NOT NULL,
    salary     NUMBER(10)    DEFAULT 50000 NOT NULL,
    PRIMARY KEY (emp_id)
);

INSERT ALL
    INTO employee (emp_id, full_name) VALUES (21, 'Samantha')
    INTO employee (emp_id, full_name) VALUES (22, 'Trump')
    INTO employee (emp_id, full_name) VALUES (23, 'Jackie Chan')
    INTO employee (emp_id, full_name) VALUES (24, 'Rama Siva')
SELECT * FROM dual;
COMMIT;

DECLARE
    v_name  employee.full_name%TYPE;   -- same type as the column, so it can never be too short
    a       NUMBER(2) := 10;
BEGIN
    IF a < 20 THEN
        SELECT full_name INTO v_name FROM employee WHERE emp_id = 21;
    ELSIF a < 50 THEN
        SELECT full_name INTO v_name FROM employee WHERE emp_id = 24;
    ELSE
        v_name := 'nobody';
    END IF;
    DBMS_OUTPUT.PUT_LINE(v_name);      -- Samantha
END;
/

-- ---------------------------------------------------------------
-- 3. Loops and exception handling
-- ---------------------------------------------------------------
DECLARE
    v_name employee.full_name%TYPE;
BEGIN
    FOR i IN 20 .. 25 LOOP
        BEGIN
            SELECT full_name INTO v_name FROM employee WHERE emp_id = i;
            DBMS_OUTPUT.PUT_LINE(i || ': ' || v_name);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE(i || ': no such employee');
        END;
    END LOOP;
END;
/

-- ---------------------------------------------------------------
-- 4. Stored procedure with IN and OUT parameters
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE give_raise (
    p_emp_id   IN  employee.emp_id%TYPE,
    p_percent  IN  NUMBER,
    p_new_sal  OUT employee.salary%TYPE
) AS
BEGIN
    IF p_percent > 20 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Raise too large');
    END IF;

    UPDATE employee
    SET salary = salary * (1 + p_percent / 100)
    WHERE emp_id = p_emp_id
    RETURNING salary INTO p_new_sal;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Employee ' || p_emp_id || ' not found');
    END IF;
END give_raise;
/

DECLARE
    v_new NUMBER;
BEGIN
    give_raise(22, 10, v_new);
    DBMS_OUTPUT.PUT_LINE('New salary: ' || v_new);
    COMMIT;
END;
/

-- From SQL*Plus a procedure without OUT params can be run with EXEC:
-- EXEC some_procedure(1);

-- ---------------------------------------------------------------
-- 5. Function, callable from SQL
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION annual_salary (p_emp_id IN NUMBER)
RETURN NUMBER
AS
    v_salary NUMBER;
BEGIN
    SELECT salary INTO v_salary FROM employee WHERE emp_id = p_emp_id;
    RETURN v_salary * 12;
END;
/

SELECT full_name, annual_salary(emp_id) AS annual FROM employee;

-- ---------------------------------------------------------------
-- 6. Dynamic SQL: ALTER SESSION isn't allowed directly in PL/SQL
-- ---------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''YYYY-MM-DD''';
END;
/

-- Bind variables with USING (never concatenate user input)
DECLARE
    v_count NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM employee WHERE emp_id > :min_id'
        INTO v_count USING 22;
    DBMS_OUTPUT.PUT_LINE(v_count);
END;
/

-- ---------------------------------------------------------------
-- 7. Package: a namespace grouping related procedures/functions
-- ---------------------------------------------------------------
CREATE OR REPLACE PACKAGE hr_pkg AS
    FUNCTION headcount RETURN NUMBER;
    PROCEDURE hire (p_id NUMBER, p_name VARCHAR2);
END hr_pkg;
/

CREATE OR REPLACE PACKAGE BODY hr_pkg AS
    FUNCTION headcount RETURN NUMBER IS
        n NUMBER;
    BEGIN
        SELECT COUNT(*) INTO n FROM employee;
        RETURN n;
    END;

    PROCEDURE hire (p_id NUMBER, p_name VARCHAR2) IS
    BEGIN
        INSERT INTO employee (emp_id, full_name) VALUES (p_id, p_name);
    END;
END hr_pkg;
/

BEGIN
    hr_pkg.hire(30, 'New Hire');
    DBMS_OUTPUT.PUT_LINE('Headcount: ' || hr_pkg.headcount);
    ROLLBACK;
END;
/

-- List your stored code
SELECT object_name, object_type, status FROM user_objects
WHERE object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY');

DROP PACKAGE hr_pkg;
DROP FUNCTION annual_salary;
DROP PROCEDURE give_raise;
DROP TABLE employee;
