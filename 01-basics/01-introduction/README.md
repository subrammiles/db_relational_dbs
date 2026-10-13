# 01 · Introduction to relational databases

## What is a relational database?

A relational database stores data in **tables** (relations). Each table has:

- **Columns** (attributes): a name and a data type, e.g. `salary NUMERIC(10,2)`.
- **Rows** (tuples / records): one entry, e.g. one employee.

Tables are linked by **keys**, and you query them with **SQL** (Structured Query Language). An **RDBMS** is the software that manages them: PostgreSQL, MySQL, Oracle, SQL Server, SQLite.

```
employees                                      departments
+--------+------------+---------+              +---------+-------------+
| emp_id | first_name | dept_id | ───────────▶ | dept_id | dept_name   |
+--------+------------+---------+   foreign    +---------+-------------+
|      3 | Priya      |       1 |     key      |       1 | Engineering |
|      8 | Karan      |       2 |              |       2 | Sales       |
+--------+------------+---------+              +---------+-------------+
   ▲ primary key                                  ▲ primary key
```

## Keys

| Key | Definition | Sample DB |
|---|---|---|
| **Primary key** | Uniquely identifies each row. Unique + NOT NULL. One per table. | `employees.emp_id` |
| **Composite key** | A primary key made of several columns | `order_items (order_id, product_id)` |
| **Foreign key** | Column that must match a primary/unique key in another (or the same) table | `employees.dept_id → departments.dept_id` |
| **Candidate key** | Any column set that *could* be the primary key | `employees.email` |
| **Alternate key** | A candidate key not chosen as primary; usually enforced with `UNIQUE` | `departments.dept_name` |
| **Surrogate key** | A meaningless generated id (`SERIAL`, `IDENTITY`, `AUTO_INCREMENT`) | every `*_id` here |
| **Natural key** | A real-world identifier (passport number, ISBN) | — |
| **Super key** | Any column set that uniquely identifies a row (candidate key + extra columns) | `(emp_id, first_name)` |

## Relationships

| Type | Example | How it's modelled |
|---|---|---|
| One-to-one | Employee ↔ parking spot | FK with a `UNIQUE` constraint |
| One-to-many | Department → employees | FK on the "many" side (`employees.dept_id`) |
| Many-to-many | Orders ↔ products | A junction table (`order_items`) with two FKs |
| Self-referencing | Employee → manager | FK to the same table (`employees.manager_id`) |

## SQL statement categories

| Category | Purpose | Statements |
|---|---|---|
| **DDL** (Definition) | Create / change structure | `CREATE`, `ALTER`, `DROP`, `TRUNCATE` |
| **DML** (Manipulation) | Change data | `INSERT`, `UPDATE`, `DELETE`, `MERGE` |
| **DQL** (Query) | Read data | `SELECT` |
| **DCL** (Control) | Permissions | `GRANT`, `REVOKE` |
| **TCL** (Transaction control) | Commit / undo groups of changes | `COMMIT`, `ROLLBACK`, `SAVEPOINT` |

## Logical order of a SELECT (very common interview question)

You **write** a query in this order:

```sql
SELECT DISTINCT dept_id, COUNT(*) AS headcount
FROM employees
WHERE salary > 50000
GROUP BY dept_id
HAVING COUNT(*) > 1
ORDER BY headcount DESC
LIMIT 3;
```

The database **evaluates** it in this order:

| Step | Clause | What happens |
|---|---|---|
| 1 | `FROM` / `JOIN` | Build the working set of rows |
| 2 | `WHERE` | Filter individual rows |
| 3 | `GROUP BY` | Collapse rows into groups |
| 4 | `HAVING` | Filter groups |
| 5 | `SELECT` | Compute output columns and aliases (window functions run here) |
| 6 | `DISTINCT` | Remove duplicate output rows |
| 7 | `ORDER BY` | Sort |
| 8 | `LIMIT` / `OFFSET` / `FETCH` | Keep a slice |

Consequences you'll meet over and over:

- You **can't** use a `SELECT` alias in `WHERE` (it doesn't exist yet), but you **can** in `ORDER BY`.
- You **can't** use an aggregate like `COUNT(*)` in `WHERE`; use `HAVING`.
- Window functions can't go in `WHERE`; wrap the query in a subquery or CTE.

## SQL vs NoSQL (short version)

| | Relational (SQL) | NoSQL (document, key-value, column, graph) |
|---|---|---|
| Schema | Fixed, enforced | Flexible |
| Relationships | Joins, foreign keys | Usually embedded or denormalised |
| Transactions | Full ACID | Varies; often per-document |
| Scaling | Vertical first; horizontal with effort | Designed for horizontal scale |
| Good for | Business data with integrity rules, reporting | Huge volume, flexible shapes, very high write rates |

## Interview questions

1. **What is the difference between a primary key and a unique key?**
   A table has one primary key and it can't be NULL. It can have many unique keys, and they allow NULLs (PostgreSQL/MySQL allow many NULLs; SQL Server allows one).
2. **Can a foreign key be NULL?** Yes, unless declared `NOT NULL`. NULL means "no related row" (Tom Wilson has no department).
3. **What is the difference between DDL and DML?** DDL changes structure, DML changes rows. In Oracle and MySQL, DDL commits automatically; in PostgreSQL, DDL is transactional and can be rolled back.
4. **In what order is a SELECT evaluated?** `FROM → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT`.
5. **What is a junction table?** A table that resolves a many-to-many relationship by holding a foreign key to each side.

Next: [02 · Create tables and data types](../02-create-table-and-data-types/)
