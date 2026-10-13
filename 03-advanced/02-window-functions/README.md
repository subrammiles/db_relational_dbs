# 02 · Window functions

A window function calculates across a set of rows **related to the current row**, without collapsing them like `GROUP BY` does. Every input row stays in the output.

```sql
function(...) OVER (
    [PARTITION BY cols]          -- split rows into groups ("windows"); omit = whole result
    [ORDER BY cols]              -- order inside each partition
    [frame clause]               -- which rows around the current one to include
)
```

```sql
-- GROUP BY: one row per department
SELECT dept_id, AVG(salary) FROM employees GROUP BY dept_id;

-- Window: every employee, plus their department's average next to them
SELECT first_name, dept_id, salary,
       AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg
FROM employees;
```

## The functions

**Ranking**

| Function | Ties | Example for salaries 100, 90, 90, 80 |
|---|---|---|
| `ROW_NUMBER()` | Always unique, ties broken arbitrarily | 1, 2, 3, 4 |
| `RANK()` | Same rank, then **gaps** | 1, 2, 2, 4 |
| `DENSE_RANK()` | Same rank, **no gaps** | 1, 2, 2, 3 |
| `NTILE(n)` | Splits rows into n buckets | quartiles, deciles |
| `PERCENT_RANK()` / `CUME_DIST()` | Relative position 0–1 | percentiles |

**Offset (value from another row)**

| Function | Returns |
|---|---|
| `LAG(col, n, default)` | Value n rows **before** (default n = 1) |
| `LEAD(col, n, default)` | Value n rows **after** |
| `FIRST_VALUE(col)` | First value in the frame |
| `LAST_VALUE(col)` | Last value in the frame (⚠️ see frames) |
| `NTH_VALUE(col, n)` | nth value in the frame |

**Aggregates as windows:** `SUM`, `AVG`, `COUNT`, `MIN`, `MAX` with `OVER (...)`: running totals, moving averages, share of total.

## Frames

With `ORDER BY` inside `OVER`, aggregates become **running** aggregates. The default frame is `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

```sql
SUM(x) OVER (ORDER BY d)                                              -- running total
AVG(x) OVER (ORDER BY d ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)     -- 3-row moving average
SUM(x) OVER (PARTITION BY g)                                          -- group total on every row (no ORDER BY)
```

- `ROWS` counts physical rows. `RANGE` treats rows with the same `ORDER BY` value as peers (they all get the same running total).
- **`LAST_VALUE` gotcha:** with the default frame, the "last" row is the current row. Use `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`, or `FIRST_VALUE` with the opposite sort.

## Where they're allowed

Window functions are computed after `WHERE`, `GROUP BY` and `HAVING`, so they can appear only in `SELECT` and `ORDER BY`. To filter on one (e.g. "rank = 1"), wrap the query in a CTE or subquery. (Some engines have `QUALIFY`: Snowflake, BigQuery, Teradata, DuckDB.)

You can use a window over an aggregate in the same query: `SUM(SUM(amount)) OVER ()` gives the grand total next to each group total.

The `WINDOW` clause names a window you use several times: `... OVER w ... WINDOW w AS (PARTITION BY dept_id ORDER BY salary DESC)`.

## Support

PostgreSQL 8.4+, Oracle 8i+ ("analytic functions"), SQL Server 2012+ (full), MySQL 8.0+, SQLite 3.25+. MySQL 5.7 has none.

## Classic interview problems solved with windows

| Problem | Pattern |
|---|---|
| Nth highest salary | `DENSE_RANK() OVER (ORDER BY salary DESC) = n` |
| Top N per group | `ROW_NUMBER() OVER (PARTITION BY g ORDER BY x DESC) <= n` |
| Remove duplicates | `ROW_NUMBER() OVER (PARTITION BY dup_cols ORDER BY id) > 1` → delete |
| Running total / cumulative % | `SUM(x) OVER (ORDER BY d)` |
| Month-over-month change | `x - LAG(x) OVER (ORDER BY month)` |
| Gaps and islands / consecutive days | `d - ROW_NUMBER() OVER (ORDER BY d)` is constant within a streak |
| Each row's share of the group | `x / SUM(x) OVER (PARTITION BY g)` |

## Interview questions

1. **ROW_NUMBER vs RANK vs DENSE_RANK?** See the table: unique numbers, gaps after ties, no gaps after ties.
2. **Window function vs GROUP BY?** GROUP BY collapses rows to one per group; a window function keeps every row and adds a computed column.
3. **Why can't you use ROW_NUMBER() in WHERE?** WHERE is evaluated before window functions. Use a subquery/CTE.
4. **What's the difference between ROWS and RANGE?** ROWS counts physical rows; RANGE groups rows with equal ORDER BY values as peers.
5. **Why does LAST_VALUE return the current row's value?** The default frame ends at the current row. Extend it to `UNBOUNDED FOLLOWING`.
6. **What does PARTITION BY do without ORDER BY?** The function sees the whole partition: e.g. department total on every row.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql)

Next: [03 · Views](../03-views/)
