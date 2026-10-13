-- 13 · Exercises with solutions
-- Needs a superuser or a role with CREATEROLE.

DO $$
DECLARE r TEXT;
BEGIN
    FOREACH r IN ARRAY ARRAY['ex_analyst', 'ex_support', 'ex_readonly'] LOOP
        IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('DROP OWNED BY %I', r);
            EXECUTE format('DROP ROLE %I', r);
        END IF;
    END LOOP;
END $$;

-- 1. Create a group role `ex_readonly` that can read every table in public,
--    including tables created later by the current user.
CREATE ROLE ex_readonly NOLOGIN;
GRANT USAGE ON SCHEMA public TO ex_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ex_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ex_readonly;

-- 2. Create a login `ex_analyst` that gets read-only access through the role.
CREATE ROLE ex_analyst LOGIN PASSWORD 'change-me' IN ROLE ex_readonly;

-- 3. Create `ex_support` that may read customers and update ONLY their email.
CREATE ROLE ex_support LOGIN PASSWORD 'change-me';
GRANT USAGE ON SCHEMA public TO ex_support;
GRANT SELECT, UPDATE (email) ON customers TO ex_support;

-- 4. Prove it: support can change an email but not a name.
SET ROLE ex_support;
UPDATE customers SET email = 'emma@mail.com' WHERE customer_id = 6;
DO $$
BEGIN
    UPDATE customers SET name = 'Hacker' WHERE customer_id = 6;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'support: %', SQLERRM;
END $$;
RESET ROLE;

-- 5. A table created after the grants is readable by the analyst (default privileges).
CREATE TABLE audit_notes (id INT, note TEXT);
SET ROLE ex_analyst;
SELECT COUNT(*) FROM audit_notes;
RESET ROLE;

-- 6. Row-level security: the analyst may only see Indian customers.
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
CREATE POLICY analyst_india ON customers FOR SELECT TO ex_readonly USING (country = 'India');
CREATE POLICY support_all   ON customers FOR ALL    TO ex_support  USING (true);
SET ROLE ex_analyst;
SELECT DISTINCT country FROM customers;           -- India only
RESET ROLE;

-- 7. Which of these is safe from SQL injection? (answers in comments)
--    a) EXECUTE 'SELECT * FROM customers WHERE city = ''' || p_city || '''';      -- UNSAFE: concatenation
--    b) EXECUTE 'SELECT * FROM customers WHERE city = $1' USING p_city;            -- SAFE: bind parameter
--    c) EXECUTE format('SELECT * FROM %I', p_table);                               -- SAFE for the identifier
--    d) EXECUTE format('SELECT * FROM customers WHERE city = %L', p_city);         -- safe (quoted literal), but prefer b)

-- Clean up
DROP POLICY analyst_india ON customers;
DROP POLICY support_all ON customers;
ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
DROP TABLE audit_notes;
DROP OWNED BY ex_analyst, ex_support, ex_readonly;
DROP ROLE ex_analyst, ex_support, ex_readonly;
