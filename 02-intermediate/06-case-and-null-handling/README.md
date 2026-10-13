# 06 · CASE expressions and NULL handling

## CASE

SQL's if/else. It's an **expression**, so it can go anywhere a value can: `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`, inside aggregates, in `UPDATE ... SET`.

**Searched CASE** (any conditions, checked top to bottom, first TRUE wins):

```sql
CASE
    WHEN salary >= 150000 THEN 'High'
    WHEN salary >=  80000 THEN 'Medium'
    ELSE 'Low'
END
```

**Simple CASE** (compare one expression to values):

```sql
CASE status
    WHEN 'delivered' THEN 'Done'
    WHEN 'cancelled' THEN 'Cancelled'
    ELSE 'In progress'
END
```

Without `ELSE`, unmatched rows get NULL. All branches must return compatible types. A simple CASE can't match NULL (`CASE x WHEN NULL` never fires); use `CASE WHEN x IS NULL`.

### Classic uses

- Bucketing values into labels (salary bands, age groups).
- **Conditional aggregation / pivoting:** `SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END)`.
- Custom sort order: `ORDER BY CASE status WHEN 'pending' THEN 1 WHEN 'shipped' THEN 2 ELSE 3 END`.
- Conditional updates: `UPDATE ... SET price = CASE WHEN ... END`.
- Avoiding division by zero.

## NULL

NULL means **unknown / missing**. It is not zero and not an empty string (except in Oracle, where `''` *is* NULL).

- Any arithmetic with NULL → NULL: `salary + NULL` is NULL.
- Any comparison with NULL → UNKNOWN: use `IS NULL` / `IS NOT NULL`.
- Aggregates skip NULLs (except `COUNT(*)`).
- `GROUP BY`, `DISTINCT` and set operators treat NULLs as equal to each other.
- In `ORDER BY`, NULLs sort last (PostgreSQL/Oracle ASC) or first (MySQL/SQL Server ASC).

## NULL functions

| Purpose | Standard | PostgreSQL | MySQL | Oracle | SQL Server |
|---|---|---|---|---|---|
| First non-NULL of a list | `COALESCE(a, b, c)` | ✔ | ✔ | ✔ | ✔ |
| Replace NULL with a value | `COALESCE(a, b)` | ✔ | `IFNULL(a, b)` | `NVL(a, b)` | `ISNULL(a, b)` |
| NULL if two values are equal | `NULLIF(a, b)` | ✔ | ✔ | ✔ | ✔ |
| If-not-null-then-else | `CASE` | — | `IF(cond, a, b)` | `NVL2(a, if_not_null, if_null)` | `IIF(cond, a, b)` |
| Equality that treats NULLs as equal | `a IS NOT DISTINCT FROM b` | ✔ | `a <=> b` | `DECODE(a, b, 1, 0) = 1` | 2022+ |

**Prefer `COALESCE`**: it's standard and takes any number of arguments.

### Divide safely

```sql
total / NULLIF(count, 0)     -- NULL instead of a division-by-zero error
```

### Oracle DECODE

```sql
DECODE(expr, search1, result1, search2, result2, ..., default)
```

A compact simple-CASE. Unlike `=`, `DECODE` treats two NULLs as equal. Prefer `CASE` in new code; you'll still see `DECODE` in legacy Oracle systems.

## Interview questions

1. **What is NULL?** A marker for a missing or unknown value. It's not equal to anything, including another NULL.
2. **COALESCE vs NVL vs ISNULL?** COALESCE is standard and takes N arguments; NVL (Oracle) and ISNULL (SQL Server) take two. NVL evaluates both arguments; COALESCE short-circuits.
3. **How do you avoid division by zero?** `x / NULLIF(y, 0)`, or `CASE WHEN y = 0 THEN NULL ELSE x / y END`.
4. **What does `NULL = NULL` return?** UNKNOWN (treated as false in `WHERE`).
5. **Count delivered and cancelled orders in one query?** Conditional aggregation: `SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END)`, or `COUNT(*) FILTER (WHERE ...)` in PostgreSQL.
6. **Can you use CASE in ORDER BY / GROUP BY?** Yes, it's an ordinary expression.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [oracle.sql](oracle.sql) · [sqlserver.sql](sqlserver.sql)

Next: [07 · Built-in functions](../07-built-in-functions/)
