-- 03 · INSERT (PostgreSQL)

DROP TABLE IF EXISTS users;
CREATE TABLE users (
    user_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    phone    VARCHAR(15) NOT NULL,
    email    VARCHAR(60) NOT NULL,
    country  CHAR(2)     DEFAULT 'IN'
);

-- One row; user_id is generated, country takes its default
INSERT INTO users (phone, email) VALUES ('123456', 'test@gmail.com');

-- Many rows in one statement
INSERT INTO users (phone, email, country) VALUES
    ('123456', 'test1@gmail.com', 'IN'),
    ('987654', 'test2@gmail.com', 'US'),
    ('555666', 'test3@gmail.com', 'UK'),
    ('777888', 'test4@gmail.com', DEFAULT);

-- Get the generated id back
INSERT INTO users (phone, email) VALUES ('111222', 'new@gmail.com')
RETURNING user_id, country;

-- A quote inside a string is written as two quotes
INSERT INTO users (phone, email) VALUES ('333444', 'o''brien@gmail.com');

SELECT * FROM users ORDER BY user_id;

-- INSERT ... SELECT: copy all Indian customers into a mailing list table
DROP TABLE IF EXISTS mailing_list;
CREATE TABLE mailing_list (name VARCHAR(100), email VARCHAR(100));

INSERT INTO mailing_list (name, email)
SELECT name, email
FROM customers
WHERE country = 'India' AND email IS NOT NULL;

SELECT * FROM mailing_list;

-- A foreign key protects you from orphans:
-- INSERT INTO employees (emp_id, first_name, last_name, dept_id, job_title, salary, hire_date)
-- VALUES (99, 'Ghost', 'User', 42, 'Engineer', 50000, '2025-01-01');
-- ERROR: insert or update on table "employees" violates foreign key constraint "employees_dept_id_fkey"

DROP TABLE users, mailing_list;
