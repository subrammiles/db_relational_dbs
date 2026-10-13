# 07 · DISTINCT and aliases

## DISTINCT

Removes duplicate **result rows**.

```sql
SELECT DISTINCT country FROM customers;
SELECT DISTINCT dept_id, job_title FROM employees;   -- unique (dept_id, job_title) pairs
SELECT COUNT(DISTINCT country) FROM customers;       -- how many different countries
```

- `DISTINCT` applies to the **whole row**, not to the first column. `SELECT DISTINCT a, b` keeps every unique pair.
- NULLs are treated as equal for `DISTINCT`, so you get at most one NULL row.
- PostgreSQL also has `DISTINCT ON (col)`: keep the first row per value of `col` according to `ORDER BY`. It's a handy "top 1 per group".
- `DISTINCT` usually needs a sort or hash of the whole result. If you find yourself adding it to "fix" duplicates from a join, the join is probably wrong.

### DISTINCT vs GROUP BY

`SELECT DISTINCT dept_id FROM employees` and `SELECT dept_id FROM employees GROUP BY dept_id` return the same rows. Use `GROUP BY` when you also need aggregates (`COUNT`, `SUM`...).

## Aliases

**Column alias**: renames an output column.

```sql
SELECT emp_id AS employee_no, salary * 12 AS "Annual Salary" FROM employees;
```

- `AS` is optional for column aliases (`SELECT emp_id employee_no`), but clearer with it.
- Use double quotes for aliases with spaces or mixed case.
- Usable in `ORDER BY`; **not** usable in `WHERE`, `GROUP BY` (except MySQL/PostgreSQL allow it in `GROUP BY`) or `HAVING` (except MySQL).

**Table alias**: a short name for a table, needed for self-joins and readable joins.

```sql
SELECT e.first_name, d.dept_name
FROM employees e
JOIN departments d ON d.dept_id = e.dept_id;
```

Oracle doesn't accept `AS` before a **table** alias (`FROM employees AS e` is an error); PostgreSQL, MySQL and SQL Server accept both.

## Interview questions

1. **Does DISTINCT apply to one column or all of them?** All selected columns together.
2. **How do you count unique values?** `COUNT(DISTINCT col)`; it ignores NULLs.
3. **DISTINCT or GROUP BY: which is faster?** For the same query they usually compile to the same plan. Choose by intent.
4. **How do you find duplicate values (not remove them)?** `GROUP BY col HAVING COUNT(*) > 1`.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [mysql.sql](mysql.sql) · [oracle.sql](oracle.sql)

Next: [08 · UPDATE and DELETE](../08-update-and-delete/)
