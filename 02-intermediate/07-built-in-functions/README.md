# 07 · Built-in functions: strings, numbers, dates, conversion

Function names differ more between databases than anything else in SQL. This table is the cheat sheet; [examples.sql](examples.sql) runs the PostgreSQL column.

## String functions

| Task | PostgreSQL | MySQL | Oracle | SQL Server |
|---|---|---|---|---|
| Length | `LENGTH(s)` | `CHAR_LENGTH(s)` (`LENGTH` = bytes) | `LENGTH(s)` | `LEN(s)` |
| Upper / lower | `UPPER`, `LOWER` | same | same | same |
| Capitalise words | `INITCAP(s)` | — | `INITCAP(s)` | — |
| Substring | `SUBSTRING(s FROM 1 FOR 3)` / `SUBSTR(s,1,3)` | `SUBSTRING(s,1,3)` | `SUBSTR(s,1,3)` | `SUBSTRING(s,1,3)` |
| Left / right n chars | `LEFT(s,n)`, `RIGHT(s,n)` | same | `SUBSTR(s,1,n)`, `SUBSTR(s,-n)` | same |
| Position of substring | `POSITION('a' IN s)` / `STRPOS(s,'a')` | `LOCATE('a', s)` / `INSTR(s,'a')` | `INSTR(s,'a')` | `CHARINDEX('a', s)` |
| Trim spaces | `TRIM(s)`, `LTRIM`, `RTRIM` | same | same | same (`TRIM` 2017+) |
| Pad | `LPAD(s,5,'0')`, `RPAD` | same | same | `RIGHT('00000'+s,5)` |
| Replace | `REPLACE(s,'a','b')` | same | same | same |
| Concatenate | `\|\|`, `CONCAT`, `CONCAT_WS(',',a,b)` | `CONCAT`, `CONCAT_WS` | `\|\|`, `CONCAT(a,b)` (2 args) | `+`, `CONCAT` |
| Split part | `SPLIT_PART(s,'@',2)` | `SUBSTRING_INDEX(s,'@',-1)` | `REGEXP_SUBSTR` | `STRING_SPLIT` |
| Reverse | `REVERSE(s)` | same | `REVERSE` (undocumented) | same |
| Regex replace | `REGEXP_REPLACE` | same (8.0+) | same | — |

## Numeric functions

| Task | Function (mostly identical everywhere) |
|---|---|
| Round to n decimals | `ROUND(x, n)` |
| Truncate | `TRUNC(x, n)` (PostgreSQL, Oracle), `TRUNCATE(x, n)` (MySQL) |
| Round up / down | `CEIL(x)` / `CEILING(x)`, `FLOOR(x)` |
| Absolute value | `ABS(x)` |
| Remainder | `MOD(a, b)` or `a % b` |
| Power / square root | `POWER(x, y)`, `SQRT(x)` |
| Random | `RANDOM()` (PG), `RAND()` (MySQL), `DBMS_RANDOM.VALUE` (Oracle) |

**Integer division:** in PostgreSQL and SQL Server `7 / 2 = 3` (both integers). MySQL returns `3.5`. Cast one side: `7 / 2.0` or `7::NUMERIC / 2`.

## Date and time functions

| Task | PostgreSQL | MySQL | Oracle | SQL Server |
|---|---|---|---|---|
| Today / now | `CURRENT_DATE`, `NOW()` | `CURDATE()`, `NOW()` | `TRUNC(SYSDATE)`, `SYSTIMESTAMP` | `CAST(GETDATE() AS DATE)`, `GETDATE()` |
| Year / month part | `EXTRACT(YEAR FROM d)` | `YEAR(d)`, `EXTRACT` | `EXTRACT(YEAR FROM d)` | `YEAR(d)`, `DATEPART` |
| Add 30 days | `d + INTERVAL '30 days'` (or `d + 30`) | `DATE_ADD(d, INTERVAL 30 DAY)` | `d + 30` | `DATEADD(day, 30, d)` |
| Add 1 month | `d + INTERVAL '1 month'` | `DATE_ADD(d, INTERVAL 1 MONTH)` | `ADD_MONTHS(d, 1)` | `DATEADD(month, 1, d)` |
| Days between | `d2 - d1` | `DATEDIFF(d2, d1)` | `d2 - d1` | `DATEDIFF(day, d1, d2)` |
| Months between | `AGE(d2, d1)` | `TIMESTAMPDIFF(MONTH, d1, d2)` | `MONTHS_BETWEEN(d2, d1)` | `DATEDIFF(month, d1, d2)` |
| First day of month | `DATE_TRUNC('month', d)` | `DATE_FORMAT(d, '%Y-%m-01')` | `TRUNC(d, 'MM')` | `DATETRUNC(month, d)` (2022) |
| Last day of month | `DATE_TRUNC('month', d) + INTERVAL '1 month - 1 day'` | `LAST_DAY(d)` | `LAST_DAY(d)` | `EOMONTH(d)` |
| Format as text | `TO_CHAR(d, 'YYYY-MM-DD')` | `DATE_FORMAT(d, '%Y-%m-%d')` | `TO_CHAR(d, 'YYYY-MM-DD')` | `FORMAT(d, 'yyyy-MM-dd')` |
| Parse text | `TO_DATE('2025-01-31', 'YYYY-MM-DD')` | `STR_TO_DATE('2025-01-31', '%Y-%m-%d')` | `TO_DATE(...)` | `CONVERT(DATE, '2025-01-31')` |
| Day of week | `EXTRACT(DOW FROM d)` (0 = Sunday) | `DAYOFWEEK(d)` (1 = Sunday) | `TO_CHAR(d, 'D')` | `DATEPART(weekday, d)` |

Use ISO literals (`'2025-01-31'` or `DATE '2025-01-31'`) to avoid locale surprises.

## Type conversion

```sql
CAST(expression AS type)          -- standard, works everywhere
expression::type                  -- PostgreSQL shorthand
CONVERT(type, expression)         -- SQL Server / MySQL (different argument order!)
TO_CHAR / TO_NUMBER / TO_DATE     -- PostgreSQL and Oracle, with format masks
```

**Implicit conversion** (comparing a `VARCHAR` column to a number, e.g. `WHERE phone = 123456`) can stop an index from being used, or fail at runtime. Compare like with like.

## Interview questions

1. **How do you get the year from a date?** `EXTRACT(YEAR FROM d)` (standard), `YEAR(d)` in MySQL/SQL Server.
2. **How do you find employees hired in the last 90 days?** `WHERE hire_date >= CURRENT_DATE - INTERVAL '90 days'`. Don't wrap the column in a function, so an index on `hire_date` can still be used.
3. **Why might `WHERE YEAR(order_date) = 2025` be slow?** The function on the column makes it non-sargable: the index on `order_date` can't be used. Write `order_date >= '2025-01-01' AND order_date < '2026-01-01'`.
4. **What is `7 / 2` in SQL?** 3 in PostgreSQL / SQL Server / SQLite (integer division); 3.5 in MySQL and Oracle.
5. **How do you extract the domain from an email?** `SPLIT_PART(email, '@', 2)` (PG), `SUBSTRING_INDEX(email, '@', -1)` (MySQL), `SUBSTR(email, INSTR(email, '@') + 1)` (Oracle).

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [sqlserver.sql](sqlserver.sql)

Next: [08 · Constraints and keys](../08-constraints-and-keys/)
