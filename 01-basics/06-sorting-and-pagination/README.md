# 06 · ORDER BY, LIMIT and pagination

## ORDER BY

```sql
SELECT ... FROM ... WHERE ...
ORDER BY expression [ASC | DESC] [NULLS FIRST | NULLS LAST], ...;
```

- `ASC` (ascending) is the default.
- Sort by several columns: `ORDER BY dept_id, salary DESC` sorts by department, then by salary (highest first) within each department.
- You can sort by an alias (`ORDER BY annual_salary`) or by position (`ORDER BY 2`; works, but brittle).
- **Without `ORDER BY`, row order is not guaranteed**, even if it looks stable today.

### Where do NULLs go?

| Database | `ASC` | `DESC` | Override |
|---|---|---|---|
| PostgreSQL, Oracle | NULLs **last** | NULLs **first** | `NULLS FIRST` / `NULLS LAST` |
| MySQL, SQLite, SQL Server | NULLs **first** | NULLs **last** | MySQL: `ORDER BY col IS NULL, col` |

## Limiting rows

| Database | First 5 rows | Rows 11–15 |
|---|---|---|
| Standard (PostgreSQL, Oracle 12c+, SQL Server 2012+) | `FETCH FIRST 5 ROWS ONLY` | `OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY` |
| PostgreSQL, MySQL, SQLite | `LIMIT 5` | `LIMIT 5 OFFSET 10` |
| MySQL shorthand | `LIMIT 5` | `LIMIT 10, 5` (offset, count) |
| SQL Server (old) | `SELECT TOP 5 ...` | — |
| Oracle (before 12c) | `WHERE ROWNUM <= 5` | Nested `ROWNUM` subqueries |

`FETCH FIRST 3 ROWS WITH TIES` also returns rows that tie with the last one (PostgreSQL 13+, Oracle 12c+).

## Pagination

**Offset pagination** (page *n* of size *s*): `ORDER BY id LIMIT s OFFSET (n-1)*s`.
Simple, but the database still reads and throws away all the skipped rows, so page 10,000 is slow. Rows inserted or deleted between requests can shift pages.

**Keyset (seek) pagination**: remember the last key you showed and continue after it.

```sql
SELECT * FROM orders
WHERE order_id > :last_seen_id
ORDER BY order_id
LIMIT 5;
```

Uses an index, stays fast on any page, and is stable while data changes. You can't jump straight to page 50, though.

## Common mistakes

- `LIMIT`/`OFFSET` without `ORDER BY`: you get an arbitrary slice.
- Paginating on a non-unique column (`ORDER BY order_date`): rows with the same date can appear on two pages or none. Add a tie-breaker: `ORDER BY order_date, order_id`.
- Oracle `ROWNUM` is assigned **before** `ORDER BY`: `WHERE ROWNUM <= 5 ORDER BY salary DESC` gives 5 random rows, sorted. Sort in a subquery first.

## Interview questions

1. **How do you get the top 3 highest paid employees?** `ORDER BY salary DESC FETCH FIRST 3 ROWS ONLY` (or `LIMIT 3`). If ties matter, `WITH TIES` or `DENSE_RANK()`.
2. **Why is OFFSET pagination slow for deep pages?** The engine must produce and discard every skipped row. Keyset pagination seeks directly with an index.
3. **What is ROWNUM vs ROW_NUMBER()?** `ROWNUM` is an Oracle pseudo-column assigned as rows are fetched, before sorting. `ROW_NUMBER() OVER (ORDER BY ...)` is a standard window function numbered after the ordering you specify.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [oracle.sql](oracle.sql)

Next: [07 · DISTINCT and aliases](../07-distinct-and-aliases/)
