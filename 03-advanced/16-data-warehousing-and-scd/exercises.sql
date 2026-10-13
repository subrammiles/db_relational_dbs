-- 16 · Exercises with solutions
-- A small employee dimension kept as SCD Type 2.

CREATE TEMP TABLE dim_employee (
    employee_key  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    emp_id        INT  NOT NULL,
    name          TEXT NOT NULL,
    job_title     TEXT NOT NULL,
    dept_name     TEXT,
    valid_from    DATE NOT NULL,
    valid_to      DATE NOT NULL DEFAULT DATE '9999-12-31',
    is_current    BOOLEAN NOT NULL DEFAULT TRUE
);

-- 1. Initial load: one current row per employee from the sample DB, valid from their hire date.
INSERT INTO dim_employee (emp_id, name, job_title, dept_name, valid_from)
SELECT e.emp_id, e.first_name || ' ' || e.last_name, e.job_title, d.dept_name, e.hire_date
FROM employees e
LEFT JOIN departments d ON d.dept_id = e.dept_id;

-- 2. On 2025-09-01 Rahul (4) is promoted to 'Senior Engineer' and Karan (8) moves to Marketing.
--    Apply both as SCD Type 2 changes in one transaction.
CREATE TEMP TABLE stg_employee (emp_id INT, name TEXT, job_title TEXT, dept_name TEXT, effective DATE);
INSERT INTO stg_employee
SELECT d.emp_id, d.name,
       CASE WHEN d.emp_id = 4 THEN 'Senior Engineer' ELSE d.job_title END,
       CASE WHEN d.emp_id = 8 THEN 'Marketing'       ELSE d.dept_name END,
       DATE '2025-09-01'
FROM dim_employee d
WHERE d.is_current;

BEGIN;
UPDATE dim_employee d
SET valid_to = s.effective, is_current = FALSE
FROM stg_employee s
WHERE d.emp_id = s.emp_id AND d.is_current
  AND (d.job_title, d.dept_name) IS DISTINCT FROM (s.job_title, s.dept_name);

INSERT INTO dim_employee (emp_id, name, job_title, dept_name, valid_from)
SELECT s.emp_id, s.name, s.job_title, s.dept_name, s.effective
FROM stg_employee s
WHERE NOT EXISTS (SELECT 1 FROM dim_employee d WHERE d.emp_id = s.emp_id AND d.is_current);
COMMIT;

-- 3. Show the full history of Rahul and Karan.
SELECT emp_id, name, job_title, dept_name, valid_from, valid_to, is_current
FROM dim_employee
WHERE emp_id IN (4, 8)
ORDER BY emp_id, valid_from;

-- 4. Headcount per department as of 2025-06-30 and as of today.
SELECT dept_name,
       COUNT(*) FILTER (WHERE DATE '2025-06-30' >= valid_from AND DATE '2025-06-30' < valid_to) AS mid_2025,
       COUNT(*) FILTER (WHERE is_current)                                                     AS now
FROM dim_employee
GROUP BY dept_name
ORDER BY dept_name NULLS LAST;

-- 5. Check data quality: no employee should have overlapping versions.
SELECT a.emp_id
FROM dim_employee a
JOIN dim_employee b
  ON a.emp_id = b.emp_id
 AND a.employee_key < b.employee_key
 AND a.valid_from < b.valid_to
 AND b.valid_from < a.valid_to;          -- expect 0 rows
