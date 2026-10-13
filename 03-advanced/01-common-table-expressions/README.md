# 01 · Common table expressions (CTEs) and recursive queries

## WITH: a named subquery

```sql
WITH dept_avg AS (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
)
SELECT e.first_name, e.salary, d.avg_salary
FROM employees e
JOIN dept_avg d ON d.dept_id = e.dept_id
WHERE e.salary > d.avg_salary;
```

A CTE is a temporary named result that exists only for that one statement.

**Why use them?**

- **Readability:** a complex query becomes a sequence of named steps, read top to bottom, instead of nesting inside out.
- **Reuse:** reference the same CTE several times in the main query.
- **Recursion:** the only standard way to walk hierarchies and graphs in SQL.

Several CTEs are separated by commas, and later ones can use earlier ones:

```sql
WITH a AS (...),
     b AS (SELECT ... FROM a ...)
SELECT ... FROM b;
```

CTEs work with `INSERT`, `UPDATE` and `DELETE` too. PostgreSQL even allows data-modifying CTEs (`WITH moved AS (DELETE ... RETURNING *) INSERT INTO archive SELECT * FROM moved`).

## CTE vs subquery vs view vs temp table

| | Lifetime | Reusable within query | Stored | Indexed |
|---|---|---|---|---|
| Subquery | One statement | No (repeat it) | No | No |
| CTE | One statement | Yes | No | No |
| View | Permanent definition | Yes, by any query | Definition only | No (materialized views: yes) |
| Temp table | Session | Yes, by any query in the session | Yes (temporarily) | Yes |

**Performance:** PostgreSQL 12+ and most other engines inline simple CTEs like subqueries. Use `WITH x AS MATERIALIZED (...)` in PostgreSQL to force computing it once. Before PostgreSQL 12, every CTE was an "optimisation fence".

## Recursive CTEs

```sql
WITH RECURSIVE chain AS (
    -- 1. Anchor member: the starting rows
    SELECT emp_id, first_name, manager_id, 1 AS level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- 2. Recursive member: joins back to the CTE itself
    SELECT e.emp_id, e.first_name, e.manager_id, c.level + 1
    FROM employees e
    JOIN chain c ON e.manager_id = c.emp_id
)
SELECT * FROM chain;
```

How it runs:

1. Run the anchor → working set (the CEO).
2. Run the recursive part using **only the rows produced in the previous step** → the CEO's direct reports.
3. Repeat with those rows → their reports, and so on.
4. Stop when a step produces no rows. The result is the `UNION ALL` of every step.

Typical uses: org charts, bill of materials (parts of parts), category trees, folder paths, graph traversal, generating number or date series.

**Guard against infinite loops** when the data might contain a cycle: track a path array and stop when a node repeats, or limit the depth (`WHERE level < 20`). SQL Server stops at 100 levels by default (`OPTION (MAXRECURSION n)`).

| Database | Keyword |
|---|---|
| PostgreSQL, MySQL 8+, SQLite | `WITH RECURSIVE` |
| SQL Server, Oracle 11gR2+ | `WITH` (no `RECURSIVE` keyword) |
| Oracle (legacy) | `CONNECT BY PRIOR emp_id = manager_id START WITH manager_id IS NULL` |

## Interview questions

1. **What is a CTE and why use it over a subquery?** A named, statement-scoped result set; more readable, can be referenced several times, and can be recursive.
2. **Is a CTE faster than a subquery?** Usually the same; most optimisers inline it. It's a readability tool, not a performance tool (except when materialisation helps avoid repeated work).
3. **Write a query that shows the whole reporting chain above an employee.** Recursive CTE starting at the employee, joining to `manager_id` each step (see examples).
4. **Generate the dates of every day in a month without a table.** Recursive CTE (or `generate_series` in PostgreSQL).
5. **What stops a recursive CTE?** An iteration that returns zero new rows. Add a depth limit or cycle check if that's not guaranteed.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [oracle.sql](oracle.sql) (`CONNECT BY`)

Next: [02 · Window functions](../02-window-functions/)
