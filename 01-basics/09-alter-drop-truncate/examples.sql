-- 09 · ALTER, DROP and TRUNCATE (PostgreSQL)
-- Works on a copy so the sample tables stay intact.

DROP TABLE IF EXISTS emp_copy;
CREATE TABLE emp_copy AS SELECT emp_id, first_name, salary, dept_id FROM employees;

-- Add a column (nullable: existing rows get NULL)
ALTER TABLE emp_copy ADD COLUMN city VARCHAR(20);

-- Add a NOT NULL column: needs a default for the existing rows
ALTER TABLE emp_copy ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- Rename a column
ALTER TABLE emp_copy RENAME COLUMN first_name TO given_name;

-- Change a column's type
ALTER TABLE emp_copy ALTER COLUMN city TYPE VARCHAR(50);

-- Set and drop a default
ALTER TABLE emp_copy ALTER COLUMN city SET DEFAULT 'Bangalore';
ALTER TABLE emp_copy ALTER COLUMN city DROP DEFAULT;

-- Add constraints after the fact
ALTER TABLE emp_copy ADD CONSTRAINT emp_copy_pk PRIMARY KEY (emp_id);
ALTER TABLE emp_copy ADD CONSTRAINT emp_copy_salary_chk CHECK (salary > 0);

-- Backfill then make NOT NULL
UPDATE emp_copy SET city = 'Unknown' WHERE city IS NULL;
ALTER TABLE emp_copy ALTER COLUMN city SET NOT NULL;

-- Drop a constraint and a column
ALTER TABLE emp_copy DROP CONSTRAINT emp_copy_salary_chk;
ALTER TABLE emp_copy DROP COLUMN is_active;

-- Rename the table
ALTER TABLE emp_copy RENAME TO staff;

SELECT * FROM staff LIMIT 3;

-- TRUNCATE: rows gone, table stays
TRUNCATE TABLE staff;
SELECT COUNT(*) AS rows_left FROM staff;      -- 0

-- In PostgreSQL even DROP can be rolled back
BEGIN;
DROP TABLE staff;
ROLLBACK;
SELECT COUNT(*) AS table_still_exists FROM staff;

-- DROP
DROP TABLE staff;
DROP TABLE IF EXISTS staff;                    -- no error the second time
