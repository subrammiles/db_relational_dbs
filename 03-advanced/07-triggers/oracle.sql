-- 07 · Triggers in Oracle
-- Inside the trigger body, the old and new rows are :OLD and :NEW (with a colon);
-- in the WHEN clause they are written without the colon.

CREATE TABLE employee (
    emp_id      NUMBER PRIMARY KEY,
    full_name   VARCHAR2(30) NOT NULL,
    salary      NUMBER(10)   NOT NULL,
    updated_at  DATE
);

CREATE TABLE salary_audit (
    emp_id      NUMBER,
    old_salary  NUMBER,
    new_salary  NUMBER,
    changed_by  VARCHAR2(30) DEFAULT USER,
    changed_at  DATE DEFAULT SYSDATE
);

-- BEFORE row trigger: modify the row before it's written
CREATE OR REPLACE TRIGGER trg_employee_before
BEFORE INSERT OR UPDATE ON employee
FOR EACH ROW
BEGIN
    :NEW.full_name  := INITCAP(TRIM(:NEW.full_name));
    :NEW.updated_at := SYSDATE;
END;
/

-- AFTER row trigger with a WHEN condition: audit salary changes
CREATE OR REPLACE TRIGGER trg_salary_audit
AFTER UPDATE OF salary ON employee
FOR EACH ROW
WHEN (OLD.salary <> NEW.salary)
BEGIN
    INSERT INTO salary_audit (emp_id, old_salary, new_salary)
    VALUES (:OLD.emp_id, :OLD.salary, :NEW.salary);
END;
/

-- Reject a change
CREATE OR REPLACE TRIGGER trg_no_pay_cut
BEFORE UPDATE OF salary ON employee
FOR EACH ROW
BEGIN
    IF :NEW.salary < :OLD.salary THEN
        RAISE_APPLICATION_ERROR(-20010, 'Salary cannot be reduced');
    END IF;
END;
/

INSERT INTO employee (emp_id, full_name, salary) VALUES (1, '  samantha  ', 50000);
UPDATE employee SET salary = 55000 WHERE emp_id = 1;
-- UPDATE employee SET salary = 1 WHERE emp_id = 1;    -- ORA-20010: Salary cannot be reduced
COMMIT;

-- full_name is 'Samantha', updated_at filled
SELECT * FROM employee;
-- 50000 -> 55000
SELECT * FROM salary_audit;

-- One trigger for several events: use INSERTING / UPDATING / DELETING
CREATE OR REPLACE TRIGGER trg_employee_events
AFTER INSERT OR UPDATE OR DELETE ON employee
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        DBMS_OUTPUT.PUT_LINE('inserted ' || :NEW.emp_id);
    ELSIF UPDATING THEN
        DBMS_OUTPUT.PUT_LINE('updated ' || :NEW.emp_id);
    ELSIF DELETING THEN
        DBMS_OUTPUT.PUT_LINE('deleted ' || :OLD.emp_id);
    END IF;
END;
/

-- Mutating table: a ROW trigger may not query its own table.
-- This trigger compiles, but any UPDATE on employee then fails with
-- ORA-04091: table EMPLOYEE is mutating, trigger/function may not see it
--
-- CREATE OR REPLACE TRIGGER trg_bad
-- AFTER UPDATE ON employee FOR EACH ROW
-- DECLARE n NUMBER;
-- BEGIN
--     SELECT COUNT(*) INTO n FROM employee;
-- END;
-- /
-- Fix: use a statement-level trigger or a COMPOUND TRIGGER.

SELECT trigger_name, triggering_event, status FROM user_triggers;

DROP TABLE salary_audit;
-- drops its triggers too
DROP TABLE employee;
