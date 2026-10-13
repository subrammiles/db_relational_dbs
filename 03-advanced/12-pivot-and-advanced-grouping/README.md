# 12 · Pivoting, ROLLUP, CUBE and GROUPING SETS

## Pivot: rows → columns

From one row per (category, status) to one row per category with a column per status.

| category | status | revenue |
|---|---|---|
| Electronics | delivered | … |
| Electronics | shipped | … |

→

| category | delivered | shipped | pending | cancelled |
|---|---|---|---|---|

**Portable way: conditional aggregation** (works everywhere)

```sql
SELECT category,
       SUM(CASE WHEN status = 'delivered' THEN revenue ELSE 0 END) AS delivered,
       SUM(CASE WHEN status = 'shipped'   THEN revenue ELSE 0 END) AS shipped
FROM ...
GROUP BY category;
```

PostgreSQL shortcut: `SUM(revenue) FILTER (WHERE status = 'delivered')`.

| Database | Native pivot |
|---|---|
| Oracle 11g+, SQL Server | `PIVOT (SUM(revenue) FOR status IN ('delivered' AS delivered, ...))` |
| PostgreSQL | `crosstab()` from the `tablefunc` extension |
| MySQL, SQLite | None; use conditional aggregation |

The output columns must be known when the query is written. A truly dynamic pivot needs dynamic SQL (or pivoting in the application/BI tool).

**Unpivot (columns → rows):** `UNION ALL` of one SELECT per column, a `CROSS JOIN LATERAL (VALUES ...)` in PostgreSQL, or `UNPIVOT` in Oracle/SQL Server.

## Subtotals and grand totals

| Clause | Groups produced for `(a, b)` |
|---|---|
| `GROUP BY a, b` | (a, b) |
| `GROUP BY ROLLUP (a, b)` | (a, b), (a), () — hierarchical subtotals + grand total |
| `GROUP BY CUBE (a, b)` | (a, b), (a), (b), () — every combination |
| `GROUP BY GROUPING SETS ((a), (b), ())` | exactly the sets you list |

Rows for a subtotal have NULL in the rolled-up column. `GROUPING(col)` returns 1 when the NULL means "subtotal" rather than a real NULL value, so you can label it:

```sql
CASE WHEN GROUPING(category) = 1 THEN 'ALL' ELSE category END
```

| Database | Support |
|---|---|
| PostgreSQL 9.5+, Oracle, SQL Server | `ROLLUP`, `CUBE`, `GROUPING SETS`, `GROUPING()` |
| MySQL | `GROUP BY a, b WITH ROLLUP`; `GROUPING()` in 8.0+; no `CUBE` / `GROUPING SETS` |
| SQLite | None; use `UNION ALL` |

## Interview questions

1. **How do you pivot rows into columns?** Conditional aggregation (`SUM(CASE WHEN ...)`), or `PIVOT` in Oracle/SQL Server.
2. **ROLLUP vs CUBE?** ROLLUP gives hierarchical subtotals (n+1 levels for n columns); CUBE gives subtotals for every combination (2ⁿ).
3. **What does GROUPING() do?** Distinguishes subtotal NULLs from real NULL values.
4. **How do you get subtotals in MySQL?** `WITH ROLLUP`.
5. **How would you show monthly sales per product as a grid?** Pivot months into columns with conditional aggregation (see examples).

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [oracle.sql](oracle.sql)

Next: [13 · Security and permissions](../13-security-and-permissions/)
