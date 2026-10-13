-- 08 · Cursors in Oracle PL/SQL

SET SERVEROUTPUT ON;

CREATE TABLE employee (
    emp_id     NUMBER PRIMARY KEY,
    full_name  VARCHAR2(30),
    dept       VARCHAR2(20),
    salary     NUMBER
);

INSERT ALL
    INTO employee VALUES (21, 'Samantha',    'IT',    60000)
    INTO employee VALUES (22, 'Trump',       'Sales', 45000)
    INTO employee VALUES (23, 'Jackie Chan', 'IT',    70000)
    INTO employee VALUES (24, 'Rama Siva',   'HR',    50000)
SELECT * FROM dual;
COMMIT;

-- ---------------------------------------------------------------
-- 1. Implicit cursor attributes after DML
-- ---------------------------------------------------------------
BEGIN
    UPDATE employee SET salary = salary + 1000 WHERE dept = 'IT';
    -- 2
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows updated');
    IF SQL%NOTFOUND THEN
        DBMS_OUTPUT.PUT_LINE('nothing updated');
    END IF;
    ROLLBACK;
END;
/

-- ---------------------------------------------------------------
-- 2. Explicit cursor: OPEN, FETCH, %NOTFOUND, %ROWCOUNT, CLOSE
-- ---------------------------------------------------------------
DECLARE
    CURSOR c_emp IS
        SELECT full_name, salary FROM employee ORDER BY salary DESC;
    v_name    employee.full_name%TYPE;
    v_salary  employee.salary%TYPE;
BEGIN
    OPEN c_emp;
    LOOP
        FETCH c_emp INTO v_name, v_salary;
        EXIT WHEN c_emp%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(c_emp%ROWCOUNT || '. ' || v_name || ' - ' || v_salary);
    END LOOP;
    CLOSE c_emp;
END;
/

-- ---------------------------------------------------------------
-- 3. %ROWTYPE record + cursor FOR loop (no OPEN/FETCH/CLOSE needed)
-- ---------------------------------------------------------------
BEGIN
    FOR r IN (SELECT * FROM employee WHERE dept = 'IT') LOOP
        DBMS_OUTPUT.PUT_LINE(r.full_name || ' works in ' || r.dept);
    END LOOP;
END;
/

-- ---------------------------------------------------------------
-- 4. Parameterised cursor
-- ---------------------------------------------------------------
DECLARE
    CURSOR c_dept (p_dept VARCHAR2) IS
        SELECT full_name FROM employee WHERE dept = p_dept;
BEGIN
    FOR r IN c_dept('IT') LOOP
        DBMS_OUTPUT.PUT_LINE('IT: ' || r.full_name);
    END LOOP;
    FOR r IN c_dept('HR') LOOP
        DBMS_OUTPUT.PUT_LINE('HR: ' || r.full_name);
    END LOOP;
END;
/

-- ---------------------------------------------------------------
-- 5. FOR UPDATE + WHERE CURRENT OF
-- ---------------------------------------------------------------
DECLARE
    CURSOR c_low IS SELECT salary FROM employee WHERE salary < 55000 FOR UPDATE OF salary;
BEGIN
    FOR r IN c_low LOOP
        UPDATE employee SET salary = r.salary * 1.10 WHERE CURRENT OF c_low;
    END LOOP;
    ROLLBACK;
END;
/

-- ---------------------------------------------------------------
-- 6. REF CURSOR returned from a procedure (e.g. to Java/Python)
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE get_dept_employees (
    p_dept   IN  VARCHAR2,
    p_result OUT SYS_REFCURSOR
) AS
BEGIN
    OPEN p_result FOR SELECT emp_id, full_name, salary FROM employee WHERE dept = p_dept;
END;
/

DECLARE
    c       SYS_REFCURSOR;
    v_id    NUMBER;
    v_name  VARCHAR2(30);
    v_sal   NUMBER;
BEGIN
    get_dept_employees('IT', c);
    LOOP
        FETCH c INTO v_id, v_name, v_sal;
        EXIT WHEN c%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(v_id || ' ' || v_name);
    END LOOP;
    CLOSE c;
END;
/

-- ---------------------------------------------------------------
-- 7. BULK COLLECT + FORALL: array processing instead of row-by-row
-- ---------------------------------------------------------------
DECLARE
    TYPE t_ids IS TABLE OF employee.emp_id%TYPE;
    v_ids t_ids;
BEGIN
    SELECT emp_id BULK COLLECT INTO v_ids FROM employee WHERE dept = 'IT';

    FORALL i IN 1 .. v_ids.COUNT
        UPDATE employee SET salary = salary * 1.05 WHERE emp_id = v_ids(i);

    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows updated in one round trip');
    ROLLBACK;
END;
/

DROP PROCEDURE get_dept_employees;
DROP TABLE employee;
