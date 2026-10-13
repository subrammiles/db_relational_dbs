-- 09 · ALTER, DROP and TRUNCATE in Oracle

CREATE TABLE employee (
    emp_id     NUMBER(15)    NOT NULL,
    full_name  VARCHAR2(20)  NOT NULL,
    PRIMARY KEY (emp_id)
);

-- Add city to employee
ALTER TABLE employee ADD city VARCHAR2(20);

-- Add several columns at once
ALTER TABLE employee ADD (email VARCHAR2(60), salary NUMBER(10,2) DEFAULT 0 NOT NULL);

-- Change type / size (MODIFY, not ALTER COLUMN)
ALTER TABLE employee MODIFY city VARCHAR2(50);

-- Rename and drop columns
ALTER TABLE employee RENAME COLUMN full_name TO name;
ALTER TABLE employee DROP COLUMN email;

DESC employee;

-- Empty the table (DDL: commits automatically and can't be rolled back)
TRUNCATE TABLE employee;

-- Drop the table. Without PURGE it goes to the recycle bin...
DROP TABLE employee;

-- ...and can be brought back
FLASHBACK TABLE employee TO BEFORE DROP;

-- Drop for good
DROP TABLE employee PURGE;
