-- 07 · Triggers in SQL Server (T-SQL)
-- SQL Server triggers are STATEMENT-level only. Instead of OLD/NEW rows they get two
-- pseudo-tables holding all affected rows: "deleted" (before) and "inserted" (after).
-- Always write triggers set-based: one UPDATE can change many rows.

DROP TABLE IF EXISTS salary_audit;
CREATE TABLE salary_audit (
    audit_id    INT IDENTITY PRIMARY KEY,
    emp_id      INT,
    old_salary  DECIMAL(10,2),
    new_salary  DECIMAL(10,2),
    changed_by  SYSNAME   DEFAULT SUSER_SNAME(),
    changed_at  DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- AFTER UPDATE audit trigger
CREATE OR ALTER TRIGGER trg_salary_audit
ON employees
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(salary) RETURN;                 -- salary column not in the SET list

    INSERT INTO salary_audit (emp_id, old_salary, new_salary)
    SELECT d.emp_id, d.salary, i.salary
    FROM deleted d
    JOIN inserted i ON i.emp_id = d.emp_id
    WHERE d.salary <> i.salary;
END;
GO

-- Validation trigger: reject raises over 30% (THROW inside a trigger rolls back the statement)
CREATE OR ALTER TRIGGER trg_limit_raise
ON employees
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON d.emp_id = i.emp_id WHERE i.salary > d.salary * 1.30)
        THROW 50010, 'A raise may not exceed 30%', 1;
END;
GO

BEGIN TRANSACTION;
UPDATE employees SET salary = salary * 1.10 WHERE dept_id = 3;     -- 2 rows → 2 audit rows
SELECT emp_id, old_salary, new_salary FROM salary_audit;

BEGIN TRY
    UPDATE employees SET salary = salary * 2 WHERE emp_id = 6;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS blocked;
END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- INSTEAD OF trigger on a view (the only kind of trigger allowed on views)
CREATE OR ALTER VIEW employee_with_dept AS
SELECT e.emp_id, e.first_name, e.last_name, d.dept_name
FROM employees e JOIN departments d ON d.dept_id = e.dept_id;
GO

CREATE OR ALTER TRIGGER trg_employee_with_dept_insert
ON employee_with_dept
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    -- email must be supplied: in SQL Server a UNIQUE column allows only ONE NULL, and Tom already has it
    INSERT INTO employees (emp_id, first_name, last_name, email, dept_id, manager_id, job_title, salary, hire_date)
    SELECT i.emp_id, i.first_name, i.last_name,
           LOWER(i.first_name + '.' + i.last_name) + '@corp.com',
           d.dept_id, 1, 'New Joiner', 50000, CAST(GETDATE() AS DATE)
    FROM inserted i JOIN departments d ON d.dept_name = i.dept_name;
END;
GO

BEGIN TRANSACTION;
INSERT INTO employee_with_dept (emp_id, first_name, last_name, dept_name) VALUES (17, 'Jai', 'Bose', 'Research');
SELECT * FROM employee_with_dept WHERE emp_id = 17;
ROLLBACK;
GO

SELECT name, OBJECT_NAME(parent_id) AS on_object, is_instead_of_trigger FROM sys.triggers;

DROP TRIGGER trg_employee_with_dept_insert;
DROP VIEW employee_with_dept;
DROP TRIGGER trg_limit_raise;
DROP TRIGGER trg_salary_audit;
DROP TABLE salary_audit;
