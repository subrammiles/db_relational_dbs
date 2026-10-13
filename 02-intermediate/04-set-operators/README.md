# 04 · Set operators: UNION, INTERSECT, EXCEPT

Set operators combine the **results of two SELECTs** vertically (rows on top of rows). Joins combine tables horizontally (columns side by side).

```sql
SELECT city FROM customers
UNION
SELECT location FROM departments;
```

| Operator | Returns | Duplicates |
|---|---|---|
| `UNION` | Rows in either query | Removed |
| `UNION ALL` | Rows in either query | **Kept** (faster: no de-duplication) |
| `INTERSECT` | Rows in both queries | Removed |
| `EXCEPT` (`MINUS` in Oracle) | Rows in the first query but not the second | Removed |

`INTERSECT ALL` / `EXCEPT ALL` exist in PostgreSQL and the standard; not in Oracle before 21c or in MySQL before 8.0.31.

## Rules

1. Each SELECT must have the **same number of columns**.
2. Corresponding columns must have **compatible types**.
3. Column **names come from the first SELECT**.
4. One `ORDER BY` at the very end applies to the combined result.
5. `INTERSECT` binds tighter than `UNION`/`EXCEPT`; use parentheses when mixing.
6. Unlike `=`, set operators treat two NULLs as equal (duplicates).

## Support

| | PostgreSQL | MySQL | Oracle | SQL Server | SQLite |
|---|---|---|---|---|---|
| `UNION [ALL]` | ✔ | ✔ | ✔ | ✔ | ✔ |
| `INTERSECT` | ✔ | 8.0.31+ | ✔ | ✔ | ✔ |
| `EXCEPT` | ✔ | 8.0.31+ | `MINUS` (21c+ also `EXCEPT`) | ✔ | ✔ |

## When to use what

- Combining similar data from different tables (current + archived orders, customers + suppliers into one contact list): `UNION ALL`.
- `UNION` only when you actually need duplicates removed; it costs a sort or hash.
- `EXCEPT` is a neat way to compare two tables ("what changed between yesterday's and today's snapshot?").

## Interview questions

1. **UNION vs UNION ALL?** `UNION` removes duplicates (extra sort/hash), `UNION ALL` keeps them and is faster. Default to `UNION ALL` unless you need de-duplication.
2. **UNION vs JOIN?** UNION stacks rows from queries with the same shape; JOIN puts columns from related rows side by side.
3. **How do you find rows in table A that are not in table B (all columns)?** `SELECT * FROM a EXCEPT SELECT * FROM b` (`MINUS` in Oracle).
4. **How do you check if two tables have identical contents?** `(A EXCEPT B) UNION ALL (B EXCEPT A)` returns nothing. (Use `EXCEPT ALL` if duplicate counts matter.)

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [oracle.sql](oracle.sql)

Next: [05 · Subqueries](../05-subqueries/)
