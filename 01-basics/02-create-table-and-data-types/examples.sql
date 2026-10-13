-- 02 · CREATE TABLE and data types (PostgreSQL)

-- A table with the most common column types and an identity primary key
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    user_id     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100)  NOT NULL,
    email       VARCHAR(100)  UNIQUE,
    phone       VARCHAR(15),
    country     CHAR(2)       DEFAULT 'IN',
    balance     NUMERIC(10,2) DEFAULT 0,
    is_active   BOOLEAN       DEFAULT TRUE,
    birth_date  DATE,
    created_at  TIMESTAMPTZ   DEFAULT CURRENT_TIMESTAMP,
    preferences JSONB
);

-- Only name is required; everything else gets a default or NULL
INSERT INTO users (name) VALUES ('Subbu');
SELECT * FROM users;

-- Why NUMERIC, not FLOAT, for money
SELECT 0.1::FLOAT + 0.2::FLOAT          AS float_sum,    -- 0.30000000000000004
       0.1::NUMERIC + 0.2::NUMERIC      AS numeric_sum;  -- 0.3

-- CHAR pads, VARCHAR doesn't
SELECT 'IN'::CHAR(5) || '|' AS char_value, octet_length('IN'::CHAR(5)) AS char_len,
       'IN'::VARCHAR(5) || '|' AS varchar_value;

-- Create a table from a query (CTAS): copies columns + data, not constraints
DROP TABLE IF EXISTS high_paid;
CREATE TABLE high_paid AS
SELECT emp_id, first_name, salary FROM employees WHERE salary > 100000;
SELECT * FROM high_paid;

-- Structure only
DROP TABLE IF EXISTS employees_empty;
CREATE TABLE employees_empty AS SELECT * FROM employees WHERE 1 = 0;
SELECT COUNT(*) AS rows_copied FROM employees_empty;     -- 0

-- Structure + defaults + constraints + indexes (PostgreSQL only)
DROP TABLE IF EXISTS employees_clone;
CREATE TABLE employees_clone (LIKE employees INCLUDING ALL);

-- Temporary table: visible only to this session, dropped on disconnect
CREATE TEMPORARY TABLE scratch (n INT);
INSERT INTO scratch VALUES (1), (2);
SELECT * FROM scratch;

-- List tables and their columns using the standard information_schema
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'employees'
ORDER BY ordinal_position;

-- Clean up
DROP TABLE users, high_paid, employees_empty, employees_clone;
