# 04 · SELECT and WHERE

## SELECT

```sql
SELECT column1, column2, expression AS alias
FROM table_name
WHERE condition;
```

- `FROM` says which table to read. In Oracle it is mandatory (use `FROM dual` for pure expressions); PostgreSQL, MySQL and SQLite allow `SELECT 1 + 1;`.
- `SELECT *` returns every column. Fine for exploring; avoid it in application code and views because the result changes when columns are added.
- Expressions are allowed: `salary * 12`, `first_name || ' ' || last_name`.

## WHERE

`WHERE` keeps only the rows for which the condition is **TRUE**. Rows where it's FALSE **or UNKNOWN (NULL)** are dropped.

| Operator | Meaning |
|---|---|
| `=` | Equal |
| `<>` or `!=` | Not equal |
| `<`, `>`, `<=`, `>=` | Comparisons (work on numbers, text and dates) |

More operators (`AND`, `OR`, `IN`, `BETWEEN`, `LIKE`, `IS NULL`) are in the [next lesson](../05-filtering-operators/).

## String concatenation

| Database | Syntax |
|---|---|
| Standard / PostgreSQL / Oracle / SQLite | `first_name \|\| ' ' \|\| last_name` |
| MySQL | `CONCAT(first_name, ' ', last_name)` (`\|\|` means OR by default) |
| SQL Server | `first_name + ' ' + last_name` or `CONCAT(...)` |

`CONCAT` works in all of them except SQLite.

## Case sensitivity

- Keywords are case-insensitive: `select` = `SELECT`.
- Unquoted identifiers: PostgreSQL folds to lower case, Oracle to UPPER case. `"MealName"` in double quotes stays exactly as written and must then always be quoted.
- String comparisons: case-sensitive in PostgreSQL and Oracle; case-insensitive by default in MySQL and SQL Server (depends on collation).

## Common mistakes

- Comparing with NULL using `=`: `WHERE email = NULL` is never true. Use `IS NULL`.
- Using double quotes for strings: `WHERE city = "Delhi"` looks for a **column** named Delhi in PostgreSQL/Oracle.
- Using a column alias in `WHERE`: `SELECT salary*12 AS annual ... WHERE annual > 100000` fails. Repeat the expression or use a subquery.

## Interview questions

1. **Why is `SELECT *` discouraged in production code?** It transfers columns you don't need, prevents index-only scans, and silently changes when the table changes.
2. **Why doesn't `WHERE col = NULL` work?** Any comparison with NULL yields UNKNOWN, and `WHERE` keeps only TRUE rows.
3. **Can you use a column alias in WHERE?** No, `WHERE` is evaluated before `SELECT`. You can in `ORDER BY` (and in MySQL, in `HAVING`).

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [oracle.sql](oracle.sql)

Next: [05 · Filtering operators](../05-filtering-operators/)
