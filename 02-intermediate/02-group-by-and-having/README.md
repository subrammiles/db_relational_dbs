# 02 · GROUP BY and HAVING

## GROUP BY

`GROUP BY` splits rows into groups that share the same values, then aggregates **each group** separately.

```sql
SELECT dept_id, COUNT(*) AS headcount, AVG(salary) AS avg_salary
FROM employees
GROUP BY dept_id;
```

```
employees                         GROUP BY dept_id                  result
dept 1: Asha, Vikram, Priya ... ─▶ group 1 (6 rows) ─▶ COUNT=6  ─▶  1 | 6 | ...
dept 2: Meera, Karan, ...       ─▶ group 2 (4 rows) ─▶ COUNT=4  ─▶  2 | 4 | ...
NULL:   Tom                     ─▶ group NULL       ─▶ COUNT=1  ─▶  NULL | 1 | ...
```

**The golden rule:** every column in `SELECT` must either be in `GROUP BY` or be inside an aggregate function. (PostgreSQL also accepts other columns of a table whose primary key is grouped. MySQL with `ONLY_FULL_GROUP_BY` off accepts anything and returns arbitrary values, which is a common source of bugs.)

- NULLs form **one group** together.
- You can group by several columns (`GROUP BY dept_id, job_title`) or an expression (`GROUP BY EXTRACT(YEAR FROM hire_date)`).
- `GROUP BY` doesn't sort. Add `ORDER BY` if you want sorted output.

## HAVING

`HAVING` filters **groups**, after aggregation. `WHERE` filters **rows**, before aggregation.

```sql
SELECT dept_id, COUNT(*) AS headcount
FROM employees
WHERE salary > 60000          -- 1. drop low-paid rows
GROUP BY dept_id              -- 2. group what's left
HAVING COUNT(*) >= 3          -- 3. keep big groups
ORDER BY headcount DESC;      -- 4. sort
```

| | `WHERE` | `HAVING` |
|---|---|---|
| Filters | Rows | Groups |
| Runs | Before `GROUP BY` | After `GROUP BY` |
| Can use aggregates | No | Yes |
| Can use row columns not in GROUP BY | Yes | No |

If a condition doesn't need an aggregate, put it in `WHERE`. It's clearer, and fewer rows get grouped.

## Going further

`ROLLUP`, `CUBE` and `GROUPING SETS` (subtotals and grand totals in one query) are in [03-advanced/12-pivot-and-advanced-grouping](../../03-advanced/12-pivot-and-advanced-grouping/).

## Interview questions

1. **WHERE vs HAVING?** See the table. Short answer: WHERE filters rows before grouping and can't use aggregates; HAVING filters groups after grouping and can.
2. **Can you use HAVING without GROUP BY?** Yes; the whole table is then one group. `SELECT COUNT(*) FROM t HAVING COUNT(*) > 10` returns one row or none.
3. **How do you find duplicate emails?** `SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1;`
4. **Departments with an average salary above the company average?** `HAVING AVG(salary) > (SELECT AVG(salary) FROM employees)`.
5. **Why does `SELECT dept_id, first_name, COUNT(*) ... GROUP BY dept_id` fail?** A group has many first names; the database can't pick one.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [mysql.sql](mysql.sql) · [oracle.sql](oracle.sql)

Next: [03 · Joins](../03-joins/)
