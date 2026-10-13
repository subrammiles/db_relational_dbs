-- 07 · Built-in functions (PostgreSQL)

-- ---------------------------------------------------------------
-- Strings
-- ---------------------------------------------------------------
SELECT first_name,
       UPPER(first_name)                     AS upper,
       LOWER(first_name)                     AS lower,
       LENGTH(first_name)                    AS len,
       LEFT(first_name, 3)                   AS first3,
       SUBSTRING(first_name FROM 2 FOR 3)    AS chars_2_to_4,
       REVERSE(first_name)                   AS reversed,
       LPAD(emp_id::TEXT, 5, '0')            AS padded_id,
       first_name || ' ' || last_name        AS full_name,
       CONCAT_WS(', ', last_name, first_name) AS last_first
FROM employees
LIMIT 5;

SELECT email,
       POSITION('@' IN email)               AS at_position,
       SPLIT_PART(email, '@', 1)            AS username,
       SPLIT_PART(email, '@', 2)            AS domain,
       REPLACE(email, '@corp.com', '@example.com') AS replaced
FROM employees
WHERE email IS NOT NULL
LIMIT 5;

SELECT TRIM('   padded   ') AS trimmed,
       INITCAP('hello sql world') AS title_case,
       REGEXP_REPLACE('Phone: 98-76-54', '[^0-9]', '', 'g') AS digits_only;

-- ---------------------------------------------------------------
-- Numbers
-- ---------------------------------------------------------------
SELECT ROUND(1234.5678, 2) AS round2,
       ROUND(1234.5678, -2) AS round_hundreds,
       TRUNC(1234.5678, 1)  AS trunc1,
       CEIL(4.1)            AS ceil,
       FLOOR(4.9)           AS floor,
       ABS(-7)              AS abs,
       MOD(17, 5)           AS mod,
       POWER(2, 10)         AS power,
       SQRT(144)            AS sqrt;

-- Integer division trap
SELECT 7 / 2            AS int_div,      -- 3
       7 / 2.0          AS numeric_div,  -- 3.5
       7::NUMERIC / 2   AS cast_div;     -- 3.5

-- Percentage of total payroll per employee
SELECT first_name, salary,
       ROUND(100.0 * salary / (SELECT SUM(salary) FROM employees), 1) AS pct_of_payroll
FROM employees
ORDER BY salary DESC
LIMIT 5;

-- ---------------------------------------------------------------
-- Dates
-- ---------------------------------------------------------------
SELECT CURRENT_DATE AS today, NOW() AS now, CURRENT_TIMESTAMP AS ts;

SELECT first_name, hire_date,
       EXTRACT(YEAR FROM hire_date)              AS hire_year,
       EXTRACT(MONTH FROM hire_date)             AS hire_month,
       TO_CHAR(hire_date, 'Day DD Mon YYYY')     AS formatted,
       DATE_TRUNC('month', hire_date)::DATE      AS month_start,
       hire_date + INTERVAL '90 days'            AS probation_end,
       (DATE '2026-01-01' - hire_date)           AS days_employed_at_2026,
       AGE(DATE '2026-01-01', hire_date)         AS tenure_at_2026,
       EXTRACT(YEAR FROM AGE(DATE '2026-01-01', hire_date)) AS full_years_at_2026
FROM employees
ORDER BY hire_date
LIMIT 5;

-- Last day of the month
SELECT (DATE_TRUNC('month', DATE '2025-02-10') + INTERVAL '1 month - 1 day')::DATE AS last_day_feb_2025;

-- Orders per weekday
SELECT TO_CHAR(order_date, 'Dy') AS weekday, COUNT(*) AS orders
FROM orders
GROUP BY TO_CHAR(order_date, 'Dy'), EXTRACT(ISODOW FROM order_date)
ORDER BY EXTRACT(ISODOW FROM order_date);

-- Sargable vs non-sargable date filters (same result; only the 2nd can use an index on order_date)
SELECT COUNT(*) FROM orders WHERE EXTRACT(YEAR FROM order_date) = 2025;
SELECT COUNT(*) FROM orders WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01';

-- ---------------------------------------------------------------
-- Conversion
-- ---------------------------------------------------------------
SELECT CAST('42' AS INT)                     AS cast_int,
       '42'::INT + 1                         AS pg_cast,
       CAST(85000 AS VARCHAR)                AS cast_text,
       TO_CHAR(1234567.891, 'FM9,999,999.00') AS formatted_number,
       TO_DATE('31/01/2025', 'DD/MM/YYYY')   AS parsed_date,
       TO_NUMBER('1,234.50', '9,999.99')     AS parsed_number;
