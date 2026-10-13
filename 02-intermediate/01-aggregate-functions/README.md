# 01 · Aggregate functions

An aggregate function turns **many rows into one value**.

| Function | Returns | NULL handling |
|---|---|---|
| `COUNT(*)` | Number of rows | Counts every row |
| `COUNT(col)` | Number of non-NULL values | Skips NULLs |
| `COUNT(DISTINCT col)` | Number of different non-NULL values | Skips NULLs |
| `SUM(col)` | Total | Skips NULLs; `NULL` if no rows |
| `AVG(col)` | Mean | Skips NULLs (so it's *not* `SUM / COUNT(*)`) |
| `MIN(col)` / `MAX(col)` | Smallest / largest (numbers, text, dates) | Skips NULLs |

Others worth knowing:

| Function | PostgreSQL | MySQL | Oracle | SQL Server |
|---|---|---|---|---|
| Concatenate values | `STRING_AGG(name, ', ')` | `GROUP_CONCAT(name SEPARATOR ', ')` | `LISTAGG(name, ', ') WITHIN GROUP (ORDER BY name)` | `STRING_AGG` |
| Median | `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY x)` | — (window trick) | `MEDIAN(x)` | `PERCENTILE_CONT` (window) |
| Std. deviation | `STDDEV(x)` | `STDDEV(x)` | `STDDEV(x)` | `STDEV(x)` |
| Conditional count | `COUNT(*) FILTER (WHERE ...)` | `SUM(cond)` | `COUNT(CASE WHEN ... THEN 1 END)` | `SUM(CASE ...)` |

## Rules

- Without `GROUP BY`, an aggregate query returns **exactly one row**, even on an empty table (`COUNT` = 0, others NULL).
- You can't mix aggregates and plain columns without `GROUP BY`: `SELECT dept_id, COUNT(*) FROM employees` is an error (older MySQL allowed it and returned an arbitrary `dept_id`).
- Aggregates can't go in `WHERE`. Filter on them with `HAVING` ([next lesson](../02-group-by-and-having/)) or a subquery.
- `AVG` of an integer column: PostgreSQL and MySQL return a decimal; SQL Server returns an **integer** (`AVG(x * 1.0)` fixes it).

## Interview questions

1. **COUNT(\*) vs COUNT(col) vs COUNT(1)?** `COUNT(*)` and `COUNT(1)` both count rows and perform the same. `COUNT(col)` counts non-NULL values of `col`.
2. **Does AVG include NULLs?** No. `AVG(bonus)` over (100, NULL, 200) is 150, not 100. Use `AVG(COALESCE(bonus, 0))` to treat NULL as zero.
3. **What does SUM return on zero rows?** NULL, not 0. Wrap it: `COALESCE(SUM(x), 0)`.
4. **How do you find the employee with the highest salary?** Not `SELECT name, MAX(salary)`. Use `ORDER BY salary DESC LIMIT 1`, or `WHERE salary = (SELECT MAX(salary) FROM employees)` (returns ties).

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql)

Next: [02 · GROUP BY and HAVING](../02-group-by-and-having/)
