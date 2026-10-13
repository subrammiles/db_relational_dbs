-- 07 · Built-in functions in SQL Server (T-SQL)

-- Strings
SELECT TOP (5)
       first_name,
       LEN(first_name)                        AS len,            -- ignores trailing spaces
       UPPER(first_name)                      AS upper,
       LEFT(first_name, 3)                    AS first3,
       SUBSTRING(first_name, 2, 3)            AS chars_2_to_4,
       REVERSE(first_name)                    AS reversed,
       first_name + ' ' + last_name           AS full_name,
       CONCAT_WS(', ', last_name, first_name) AS last_first,     -- 2017+
       RIGHT('00000' + CAST(emp_id AS VARCHAR(5)), 5) AS padded_id
FROM employees;

SELECT TOP (3) email,
       CHARINDEX('@', email)                          AS at_position,
       LEFT(email, CHARINDEX('@', email) - 1)         AS username,
       SUBSTRING(email, CHARINDEX('@', email) + 1, 100) AS domain
FROM employees
WHERE email IS NOT NULL;

SELECT TRIM('  padded  ') AS trimmed,                            -- 2017+
       REPLACE('a-b-c', '-', '+') AS replaced,
       STRING_AGG(first_name, ', ') WITHIN GROUP (ORDER BY first_name) AS team   -- 2017+
FROM employees WHERE dept_id = 2;

SELECT value AS part FROM STRING_SPLIT('red,green,blue', ',');

-- Numbers: integer division truncates
SELECT 7 / 2 AS int_div, 7 / 2.0 AS decimal_div, 7 % 2 AS modulo,
       ROUND(1234.5678, 2) AS round2, CEILING(4.1) AS ceil, FLOOR(4.9) AS floor;

-- Dates
SELECT GETDATE() AS now, CAST(GETDATE() AS DATE) AS today, SYSUTCDATETIME() AS utc_now;

SELECT TOP (5) first_name, hire_date,
       YEAR(hire_date)                            AS hire_year,
       DATEPART(QUARTER, hire_date)               AS quarter,
       DATENAME(WEEKDAY, hire_date)               AS weekday,
       DATEADD(DAY, 90, hire_date)                AS probation_end,
       DATEDIFF(DAY, hire_date, '2026-01-01')     AS days_employed_at_2026,
       EOMONTH(hire_date)                         AS month_end,
       DATEFROMPARTS(YEAR(hire_date), 1, 1)       AS year_start,
       FORMAT(hire_date, 'dd MMM yyyy')           AS formatted
FROM employees
ORDER BY hire_date;

-- Sargable date filter
SELECT COUNT(*) FROM orders WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01';

-- Conversion: CAST (standard), CONVERT (with style codes), TRY_CAST returns NULL instead of failing
SELECT CAST('42' AS INT)                     AS cast_int,
       CONVERT(VARCHAR(10), GETDATE(), 103)  AS dd_mm_yyyy,     -- style 103 = dd/mm/yyyy
       TRY_CAST('abc' AS INT)                AS try_cast_null,
       TRY_CONVERT(DATE, '31/01/2025', 103)  AS parsed_date;
