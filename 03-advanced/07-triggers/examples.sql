-- 07 · Triggers (PostgreSQL)
-- In PostgreSQL a trigger calls a function that RETURNS trigger.

-- ---------------------------------------------------------------
-- 1. AFTER UPDATE audit trail: log every salary change
-- ---------------------------------------------------------------
DROP TABLE IF EXISTS salary_audit;
CREATE TABLE salary_audit (
    audit_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    emp_id      INT NOT NULL,
    old_salary  NUMERIC(10,2),
    new_salary  NUMERIC(10,2),
    changed_by  TEXT        NOT NULL DEFAULT current_user,
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION log_salary_change()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO salary_audit (emp_id, old_salary, new_salary)
    VALUES (OLD.emp_id, OLD.salary, NEW.salary);
    RETURN NEW;                       -- ignored for AFTER triggers, but required
END;
$$;

CREATE TRIGGER trg_salary_audit
AFTER UPDATE OF salary ON employees
FOR EACH ROW
WHEN (OLD.salary IS DISTINCT FROM NEW.salary)      -- only real changes
EXECUTE FUNCTION log_salary_change();

UPDATE employees SET salary = salary * 1.10 WHERE dept_id = 3;   -- 2 rows → 2 audit rows
UPDATE employees SET job_title = 'Senior Recruiter' WHERE emp_id = 12;   -- salary not touched → no audit
SELECT emp_id, old_salary, new_salary, changed_by FROM salary_audit;

-- ---------------------------------------------------------------
-- 2. BEFORE INSERT/UPDATE: normalise data and set updated_at
-- ---------------------------------------------------------------
ALTER TABLE customers ADD COLUMN updated_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION customers_before_write()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.email      := LOWER(TRIM(NEW.email));     -- modify the row before it's stored
    NEW.updated_at := now();
    RETURN NEW;                                   -- returning NULL would silently skip the row
END;
$$;

CREATE TRIGGER trg_customers_before_write
BEFORE INSERT OR UPDATE ON customers
FOR EACH ROW
EXECUTE FUNCTION customers_before_write();

INSERT INTO customers (customer_id, name, email, city, country, signup_date)
VALUES (11, 'Nina Roy', '  Nina.Roy@Mail.COM ', 'Kolkata', 'India', CURRENT_DATE);
SELECT customer_id, email, updated_at IS NOT NULL AS has_updated_at FROM customers WHERE customer_id = 11;

-- ---------------------------------------------------------------
-- 3. BEFORE trigger that rejects a change (business rule a CHECK can't express:
--    a raise may not exceed 30% in one step)
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION limit_raise()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.salary > OLD.salary * 1.30 THEN
        RAISE EXCEPTION 'Raise for employee % exceeds 30%% (% -> %)', OLD.emp_id, OLD.salary, NEW.salary;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_limit_raise
BEFORE UPDATE OF salary ON employees
FOR EACH ROW
EXECUTE FUNCTION limit_raise();

DO $$
BEGIN
    UPDATE employees SET salary = salary * 2 WHERE emp_id = 6;
EXCEPTION WHEN raise_exception THEN
    RAISE NOTICE 'Blocked: %', SQLERRM;
END $$;

-- ---------------------------------------------------------------
-- 4. AFTER INSERT/DELETE keeping stock in sync with order lines
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync_stock()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE products SET stock = stock - NEW.quantity WHERE product_id = NEW.product_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE products SET stock = stock + OLD.quantity WHERE product_id = OLD.product_id;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_sync_stock
AFTER INSERT OR DELETE ON order_items
FOR EACH ROW
EXECUTE FUNCTION sync_stock();

SELECT stock FROM products WHERE product_id = 2;                -- 200
INSERT INTO orders VALUES (19, 9, CURRENT_DATE, 'pending');
INSERT INTO order_items VALUES (19, 2, 5, 800);
SELECT stock FROM products WHERE product_id = 2;                -- 195
DELETE FROM order_items WHERE order_id = 19;
SELECT stock FROM products WHERE product_id = 2;                -- 200 again

-- ---------------------------------------------------------------
-- 5. Statement-level trigger with a transition table: one log row per statement
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bulk_log (logged_at TIMESTAMPTZ DEFAULT now(), table_name TEXT, rows_changed INT);

CREATE OR REPLACE FUNCTION log_bulk_update()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO bulk_log (table_name, rows_changed)
    SELECT TG_TABLE_NAME, COUNT(*) FROM changed_rows;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_products_bulk
AFTER UPDATE ON products
REFERENCING NEW TABLE AS changed_rows
FOR EACH STATEMENT
EXECUTE FUNCTION log_bulk_update();

UPDATE products SET price = price * 1.05 WHERE category = 'Electronics';   -- 5 rows, 1 log entry
SELECT table_name, rows_changed FROM bulk_log;

-- ---------------------------------------------------------------
-- 6. INSTEAD OF trigger: make a join view insertable
-- ---------------------------------------------------------------
CREATE OR REPLACE VIEW employee_with_dept AS
SELECT e.emp_id, e.first_name, e.last_name, d.dept_name
FROM employees e JOIN departments d ON d.dept_id = e.dept_id;

CREATE OR REPLACE FUNCTION employee_with_dept_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO employees (emp_id, first_name, last_name, dept_id, manager_id, job_title, salary, hire_date)
    SELECT NEW.emp_id, NEW.first_name, NEW.last_name, d.dept_id, 1, 'New Joiner', 50000, CURRENT_DATE
    FROM departments d WHERE d.dept_name = NEW.dept_name;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_employee_with_dept_insert
INSTEAD OF INSERT ON employee_with_dept
FOR EACH ROW
EXECUTE FUNCTION employee_with_dept_insert();

INSERT INTO employee_with_dept (emp_id, first_name, last_name, dept_name) VALUES (17, 'Jai', 'Bose', 'Research');
SELECT * FROM employee_with_dept WHERE emp_id = 17;

-- List triggers
SELECT event_object_table AS table_name, trigger_name, action_timing, event_manipulation
FROM information_schema.triggers
ORDER BY table_name, trigger_name;

-- Clean up (dropping a trigger: DROP TRIGGER name ON table)
DROP VIEW employee_with_dept;
DROP TRIGGER trg_products_bulk ON products;
DROP TRIGGER trg_sync_stock ON order_items;
DROP TRIGGER trg_limit_raise ON employees;
DROP TRIGGER trg_salary_audit ON employees;
DROP TRIGGER trg_customers_before_write ON customers;
DROP FUNCTION employee_with_dept_insert, log_bulk_update, sync_stock, limit_raise,
              customers_before_write, log_salary_change;
DROP TABLE bulk_log, salary_audit;
ALTER TABLE customers DROP COLUMN updated_at;
