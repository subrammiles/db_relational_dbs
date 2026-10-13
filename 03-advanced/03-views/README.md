# 03 · Views and materialized views

## View

A view is a **saved query** that you use like a table. It stores no data (only the definition); every time you select from it, the query runs.

```sql
CREATE VIEW customer_orders AS
SELECT c.name, c.city, o.order_id, o.order_date, o.status
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id;

SELECT * FROM customer_orders WHERE city = 'London';
```

| Command | PostgreSQL | MySQL | Oracle |
|---|---|---|---|
| Create or change | `CREATE OR REPLACE VIEW v AS ...` | same | same |
| Drop | `DROP VIEW [IF EXISTS] v` | same | `DROP VIEW v` |
| List | `\dv` | `SHOW FULL TABLES WHERE Table_type = 'VIEW'` | `SELECT view_name FROM user_views` |
| Show definition | `\d+ v` / `pg_get_viewdef('v')` | `SHOW CREATE VIEW v` | `SELECT text FROM user_views WHERE view_name = 'V'` |

`CREATE OR REPLACE` in PostgreSQL can only **add** columns at the end; to remove or rename columns, drop and recreate.

### Why use views

- **Simplicity:** hide a complex join behind a simple name.
- **Security:** grant access to a view that exposes only some columns/rows, not the base table (e.g. employees without salary).
- **Stable interface:** the base tables can be refactored while the view keeps the same shape for applications and reports.
- **Consistency:** one definition of "active customer" or "revenue" instead of copies in every report.

### Updatable views

A simple view (one table, no `DISTINCT`, `GROUP BY`, aggregates, window functions, `UNION`, or `LIMIT`) can be the target of `INSERT`/`UPDATE`/`DELETE`; the change goes to the base table.

`WITH CHECK OPTION` rejects changes that would produce rows the view can't see:

```sql
CREATE VIEW bangalore_depts AS
SELECT * FROM departments WHERE location = 'Bangalore'
WITH CHECK OPTION;

UPDATE bangalore_depts SET location = 'Delhi' WHERE dept_id = 1;   -- ERROR: violates check option
```

Complex views can be made writable with `INSTEAD OF` triggers.

### Drawbacks

- A view over views over views is hard to understand and tune.
- Selecting a few columns from a wide view may still do all its joins (optimisers remove some, not all).
- `SELECT *` in a view definition is expanded once at creation time; new base-table columns don't appear.
- Dropping a base table or column fails (or cascades) while views depend on it.

## Materialized view

A materialized view **stores the result** like a table. Reads are fast; the data is a snapshot until you refresh it.

```sql
CREATE MATERIALIZED VIEW monthly_revenue AS
SELECT DATE_TRUNC('month', order_date) AS month, SUM(...) AS revenue
FROM ... GROUP BY 1;

REFRESH MATERIALIZED VIEW monthly_revenue;                 -- blocks readers while running
REFRESH MATERIALIZED VIEW CONCURRENTLY monthly_revenue;    -- needs a unique index; readers not blocked
```

| | View | Materialized view |
|---|---|---|
| Stores data | No | Yes |
| Always current | Yes | No, until refreshed |
| Read speed | Same as the query | Fast (precomputed, can be indexed) |
| Typical use | Abstraction, security | Dashboards, reports, expensive aggregations |

| Database | Support |
|---|---|
| PostgreSQL | `CREATE MATERIALIZED VIEW`, manual `REFRESH` |
| Oracle | `CREATE MATERIALIZED VIEW ... REFRESH FAST/COMPLETE ON COMMIT/ON DEMAND`, query rewrite |
| SQL Server | "Indexed views" (`WITH SCHEMABINDING` + a unique clustered index), maintained automatically |
| MySQL | None; emulate with a table + scheduled event or triggers |

## Interview questions

1. **What is a view? Does it store data?** A stored query; it stores no data (unless materialized).
2. **View vs table?** A table stores rows; a view computes them from tables on every query.
3. **View vs materialized view?** Materialized stores the result and must be refreshed; normal view is always current but runs the query each time.
4. **Can you update a view?** Yes, if it's simple (one base table, no aggregates/DISTINCT/GROUP BY), or via INSTEAD OF triggers.
5. **What does WITH CHECK OPTION do?** Rejects inserts/updates through the view that would create rows the view's WHERE doesn't include.
6. **How do views help security?** Grant SELECT on a view that hides sensitive columns or rows, and no privilege on the base table.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [mysql.sql](mysql.sql) · [oracle.sql](oracle.sql)

Next: [04 · Indexes](../04-indexes/)
