-- 04 · Indexes and EXPLAIN in MySQL
--
-- Indexes make searches faster. Without an index the database must check every row:
--   Check row 1 -> Alice   no
--   Check row 2 -> Bob     no
--   ...
--   Check row 5 -> Eva     yes
-- This is a full table scan. With millions of rows it becomes slow.

DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    emp_id      INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(50),
    department  VARCHAR(50),
    salary      INT,
    city        VARCHAR(50)
);

INSERT INTO employees (name, department, salary, city) VALUES
    ('Alice',   'IT',    60000, 'Bangalore'),
    ('Bob',     'HR',    45000, 'Delhi'),
    ('Charlie', 'IT',    70000, 'Mumbai'),
    ('David',   'Sales', 50000, 'Bangalore'),
    ('Eva',     'HR',    55000, 'Delhi');

-- No index on name yet -> type: ALL (full table scan), key: NULL
EXPLAIN SELECT * FROM employees WHERE name = 'Eva';

-- Create an index on the column you filter by
CREATE INDEX idx_name ON employees (name);

-- Now -> type: ref, key: idx_name
EXPLAIN SELECT * FROM employees WHERE name = 'Eva';

-- An index on a DIFFERENT column doesn't help this query:
CREATE INDEX idx_department ON employees (department);
EXPLAIN SELECT * FROM employees WHERE department = 'HR';   -- uses idx_department
EXPLAIN SELECT * FROM employees WHERE city = 'Delhi';      -- type: ALL (no index on city)

-- Composite index: leftmost prefix rule
CREATE INDEX idx_dept_salary ON employees (department, salary);
EXPLAIN SELECT * FROM employees WHERE department = 'IT' AND salary > 50000;  -- can use idx_dept_salary
EXPLAIN SELECT * FROM employees WHERE salary > 50000;                        -- leading column missing

-- Function on the column: index not used...
EXPLAIN SELECT * FROM employees WHERE UPPER(name) = 'EVA';
-- ...unless you create a functional index (MySQL 8.0.13+, note the double parentheses)
CREATE INDEX idx_upper_name ON employees ((UPPER(name)));

-- Measure the real execution (MySQL 8.0.18+)
EXPLAIN ANALYZE SELECT * FROM employees WHERE name = 'Eva';

-- List and drop
SHOW INDEX FROM employees;
DROP INDEX idx_department ON employees;

DROP TABLE employees;

-- Common EXPLAIN "type" values, best to worst:
--   const / eq_ref : one row via primary/unique key
--   ref            : index lookup on a non-unique value
--   range          : index range scan (BETWEEN, >, <, IN)
--   index          : full scan of the index
--   ALL            : full table scan
