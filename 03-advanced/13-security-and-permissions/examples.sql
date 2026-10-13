-- 13 · Roles, privileges and row-level security (PostgreSQL)
-- Needs a superuser or a role with CREATEROLE (e.g. connect as postgres).
-- Roles are cluster-wide, so the script removes leftovers first and drops them at the end.

-- Remove roles left over from a previous run
DO $$
DECLARE
    r TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY['tut_alice', 'tut_bob', 'tut_reporting', 'tut_app'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('DROP OWNED BY %I', r);
            EXECUTE format('DROP ROLE %I', r);
        END IF;
    END LOOP;
END $$;

-- ---------------------------------------------------------------
-- 1. Group roles (no login) carry the privileges
-- ---------------------------------------------------------------
CREATE ROLE tut_reporting NOLOGIN;      -- read-only analysts
CREATE ROLE tut_app       NOLOGIN;      -- the application

GRANT USAGE ON SCHEMA public TO tut_reporting, tut_app;

-- Reporting: read everything except raw employee salaries
GRANT SELECT ON departments, customers, products, orders, order_items TO tut_reporting;
GRANT SELECT (emp_id, first_name, last_name, dept_id, job_title) ON employees TO tut_reporting;  -- column-level

-- App: read/write shop tables, no DDL, no DELETE on orders
GRANT SELECT, INSERT, UPDATE         ON customers, orders, order_items TO tut_app;
GRANT SELECT, UPDATE (stock)         ON products                       TO tut_app;
GRANT DELETE                         ON order_items                    TO tut_app;

-- ---------------------------------------------------------------
-- 2. Login roles (users) get privileges by membership
-- ---------------------------------------------------------------
CREATE ROLE tut_alice LOGIN PASSWORD 'change-me';
CREATE ROLE tut_bob   LOGIN PASSWORD 'change-me';
GRANT tut_reporting TO tut_alice;
GRANT tut_app       TO tut_bob;

-- ---------------------------------------------------------------
-- 3. Test the privileges by switching role in this session
-- ---------------------------------------------------------------
SET ROLE tut_alice;
SELECT current_user;
SELECT COUNT(*) AS visible_orders FROM orders;                           -- allowed
SELECT first_name, job_title FROM employees LIMIT 3;                     -- allowed columns
DO $$
BEGIN
    PERFORM salary FROM employees;                                       -- column not granted
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'alice: %', SQLERRM;
END $$;
DO $$
BEGIN
    UPDATE products SET price = 1;                                       -- read-only role
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'alice: %', SQLERRM;
END $$;
RESET ROLE;

SET ROLE tut_bob;
UPDATE products SET stock = stock WHERE product_id = 1;                  -- allowed: UPDATE (stock)
DO $$
BEGIN
    UPDATE products SET price = 1 WHERE product_id = 1;                  -- price not granted
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'bob: %', SQLERRM;
END $$;
DO $$
BEGIN
    DELETE FROM orders WHERE order_id = 18;                              -- DELETE not granted
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'bob: %', SQLERRM;
END $$;
DO $$
BEGIN
    EXECUTE 'DROP TABLE accounts';                                       -- not the owner
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'bob: %', SQLERRM;
END $$;
RESET ROLE;

-- REVOKE takes a privilege away
REVOKE UPDATE (stock) ON products FROM tut_app;

-- Inspect grants
SELECT grantee, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee LIKE 'tut_%'
ORDER BY grantee, table_name, privilege_type;

-- ---------------------------------------------------------------
-- 4. Row-level security: each customer sees only their own orders
-- ---------------------------------------------------------------
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- The app sets app.customer_id per request (SET app.customer_id = '3'),
-- and the policy filters every query on orders automatically.
CREATE POLICY orders_own_rows ON orders
    FOR ALL
    TO tut_app
    USING (customer_id = NULLIF(current_setting('app.customer_id', true), '')::INT)
    WITH CHECK (customer_id = NULLIF(current_setting('app.customer_id', true), '')::INT);

SET ROLE tut_bob;
SET app.customer_id = '3';
SELECT order_id, customer_id FROM orders;                                -- only John Smith's orders
DO $$
BEGIN
    INSERT INTO orders VALUES (50, 1, CURRENT_DATE, 'pending');         -- someone else's customer_id
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'RLS: %', SQLERRM;
END $$;
RESET app.customer_id;
RESET ROLE;

-- The table owner (we) still sees everything unless FORCE ROW LEVEL SECURITY is set
SELECT COUNT(*) AS owner_sees FROM orders;

DROP POLICY orders_own_rows ON orders;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------
-- 5. SECURITY DEFINER function: expose an aggregate without exposing salaries
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION dept_avg_salary(p_dept INT)
RETURNS NUMERIC
LANGUAGE sql
SECURITY DEFINER                    -- runs with the owner's rights
SET search_path = public            -- always pin search_path in SECURITY DEFINER functions
AS $$
    SELECT ROUND(AVG(salary), 0) FROM employees WHERE dept_id = p_dept;
$$;

REVOKE ALL ON FUNCTION dept_avg_salary(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION dept_avg_salary(INT) TO tut_reporting;

SET ROLE tut_alice;
SELECT dept_avg_salary(1) AS engineering_avg;                            -- works, though salary is hidden
RESET ROLE;

-- ---------------------------------------------------------------
-- 6. SQL injection inside the database, and the safe version
-- ---------------------------------------------------------------
-- UNSAFE: concatenates input into SQL text
CREATE OR REPLACE FUNCTION find_customer_unsafe(p_name TEXT)
RETURNS SETOF customers
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE 'SELECT * FROM customers WHERE name = ''' || p_name || '''';
END;
$$;

SELECT name FROM find_customer_unsafe('John Smith');                     -- 1 row, as intended
SELECT name FROM find_customer_unsafe($$x' OR '1'='1$$);                 -- every customer leaks!

-- SAFE: the value is a bind parameter, never parsed as SQL
CREATE OR REPLACE FUNCTION find_customer_safe(p_name TEXT)
RETURNS SETOF customers
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE 'SELECT * FROM customers WHERE name = $1' USING p_name;
END;
$$;

SELECT name FROM find_customer_safe($$x' OR '1'='1$$);                   -- 0 rows

-- Identifiers (e.g. a sort column chosen by the user) can't be parameters: allow-list them
CREATE OR REPLACE FUNCTION customers_sorted(p_sort TEXT)
RETURNS SETOF customers
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_sort NOT IN ('name', 'city', 'signup_date') THEN
        RAISE EXCEPTION 'invalid sort column %', p_sort;
    END IF;
    RETURN QUERY EXECUTE format('SELECT * FROM customers ORDER BY %I', p_sort);
END;
$$;

SELECT name, city FROM customers_sorted('city') LIMIT 3;

-- ---------------------------------------------------------------
-- Clean up
-- ---------------------------------------------------------------
DROP FUNCTION customers_sorted, find_customer_safe, find_customer_unsafe, dept_avg_salary;
DROP OWNED BY tut_alice, tut_bob, tut_reporting, tut_app;    -- removes their grants
DROP ROLE tut_alice, tut_bob, tut_reporting, tut_app;
