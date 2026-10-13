# 05 · Subqueries

A subquery is a `SELECT` inside another statement.

## Kinds of subquery

| Kind | Returns | Where | Example |
|---|---|---|---|
| **Scalar** | One value (1 row × 1 column) | Anywhere a value fits: `SELECT`, `WHERE`, `SET` | `WHERE salary > (SELECT AVG(salary) FROM employees)` |
| **Row / list** | One column, many rows | `IN`, `ANY`, `ALL` | `WHERE dept_id IN (SELECT dept_id FROM departments WHERE location = 'Bangalore')` |
| **Table** (derived table, inline view) | Many rows × many columns | `FROM` (needs an alias) | `FROM (SELECT dept_id, AVG(salary) avg_sal FROM employees GROUP BY dept_id) d` |
| **Correlated** | Re-evaluated **for each outer row**; refers to the outer query | `WHERE`, `SELECT` | `WHERE salary > (SELECT AVG(salary) FROM employees e2 WHERE e2.dept_id = e.dept_id)` |
| **EXISTS** | TRUE if the subquery returns any row | `WHERE` | `WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)` |

A scalar subquery that returns more than one row is an **error**; one that returns no rows gives NULL.

## IN, ANY / SOME, ALL, EXISTS

```sql
x IN (subquery)          -- equals any value in the list
x = ANY (subquery)       -- same as IN
x > ANY (subquery)       -- greater than at least one value  (> the minimum)
x > ALL (subquery)       -- greater than every value         (> the maximum)
EXISTS (subquery)        -- subquery returns at least one row
NOT EXISTS (subquery)    -- subquery returns no rows
```

**`x > ALL (empty set)` is TRUE**, and `x > ANY (empty set)` is FALSE.

### NOT IN vs NOT EXISTS (classic interview trap)

If the subquery returns **any NULL**, `NOT IN` returns **no rows**, because `x NOT IN (1, NULL)` is `x <> 1 AND x <> NULL` → UNKNOWN. `NOT EXISTS` doesn't have this problem. **Prefer `NOT EXISTS`**, or add `WHERE col IS NOT NULL` inside the `NOT IN` subquery.

## Subquery vs JOIN

- Many subqueries can be rewritten as joins and vice versa. Modern optimisers often produce the same plan.
- Use `EXISTS` / `IN` when you only need to *check* the other table (semi-join): no duplicate rows, no `DISTINCT` needed.
- Use a `JOIN` when you need *columns* from the other table.
- A correlated subquery in `SELECT` runs per row. On large tables, a join with `GROUP BY` or a window function is usually faster.
- Deeply nested subqueries are hard to read. Use CTEs ([03-advanced/01](../../03-advanced/01-common-table-expressions/)).

## Interview questions

1. **What is a correlated subquery?** One that references a column from the outer query, so it's logically evaluated once per outer row.
2. **Employees who earn more than the average of their own department?** Correlated subquery (see examples) or a window function `AVG(salary) OVER (PARTITION BY dept_id)`.
3. **Second highest salary?** `SELECT MAX(salary) FROM employees WHERE salary < (SELECT MAX(salary) FROM employees);` For the Nth, use `DENSE_RANK()`.
4. **IN vs EXISTS: which is faster?** Usually equivalent in modern engines. `EXISTS` can stop at the first match; `NOT EXISTS` is the safe choice with NULLs.
5. **Can a subquery be used in FROM?** Yes, as a derived table; it must have an alias in most databases.
6. **What happens if a scalar subquery returns two rows?** Runtime error ("more than one row returned by a subquery used as an expression").

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql)

Next: [06 · CASE and NULL handling](../06-case-and-null-handling/)
