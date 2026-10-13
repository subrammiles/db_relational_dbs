# 08 · Constraints and keys

Constraints are rules the database enforces on every insert and update. They are the cheapest bug prevention there is: bad data never gets in, no matter which application writes it.

| Constraint | Guarantees | Example |
|---|---|---|
| `NOT NULL` | Column always has a value | `name VARCHAR(100) NOT NULL` |
| `UNIQUE` | No two rows share the value (NULLs allowed, usually many) | `email VARCHAR(100) UNIQUE` |
| `PRIMARY KEY` | `UNIQUE` + `NOT NULL`; one per table; identifies the row | `emp_id INT PRIMARY KEY` |
| `FOREIGN KEY` | Value must exist in the referenced table (or be NULL) | `dept_id INT REFERENCES departments(dept_id)` |
| `CHECK` | A boolean condition must not be FALSE | `CHECK (salary > 0)` |
| `DEFAULT` | Value used when none is given (not strictly a constraint) | `status VARCHAR(20) DEFAULT 'pending'` |
| `EXCLUDE` (PostgreSQL) | No two rows "overlap" (e.g. room bookings) | `EXCLUDE USING gist (room WITH =, during WITH &&)` |

## Column vs table constraints, and naming

```sql
CREATE TABLE enrolments (
    student_id  INT NOT NULL,
    course_id   INT NOT NULL,
    grade       CHAR(1),
    CONSTRAINT enrolments_pk     PRIMARY KEY (student_id, course_id),         -- composite: table-level
    CONSTRAINT enrolments_grade  CHECK (grade IN ('A','B','C','D','F')),
    CONSTRAINT enrolments_course FOREIGN KEY (course_id) REFERENCES courses (course_id)
);
```

Name your constraints. The name shows up in error messages, and you need it to drop the constraint later.

## Foreign key actions

What happens to child rows when the parent row is deleted or its key is updated?

| Action | On parent delete |
|---|---|
| `NO ACTION` / `RESTRICT` (default) | Refuse the delete while children exist |
| `CASCADE` | Delete the children too |
| `SET NULL` | Set the children's FK column to NULL |
| `SET DEFAULT` | Set it to its default |

```sql
order_id INT REFERENCES orders(order_id) ON DELETE CASCADE
```

`ON DELETE CASCADE` fits "part-of" relationships (order → order_items). Avoid it where deleting a parent should be a deliberate decision (department → employees).

**Index your foreign key columns.** PostgreSQL and Oracle don't do it automatically (MySQL InnoDB does). Without the index, every parent delete scans the child table, and joins on the FK are slower.

## Deferrable constraints

In PostgreSQL and Oracle a constraint can be checked at `COMMIT` instead of per statement:

```sql
FOREIGN KEY (manager_id) REFERENCES employees DEFERRABLE INITIALLY DEFERRED
```

Useful for circular references or swapping unique values within a transaction.

## Dialect notes

- **MySQL** enforces `CHECK` only from 8.0.16; earlier versions parsed and silently ignored it. MyISAM tables ignore foreign keys entirely.
- **SQLite** enforces foreign keys only after `PRAGMA foreign_keys = ON;` (per connection).
- **UNIQUE and NULL:** PostgreSQL, MySQL, Oracle and SQLite allow many NULLs in a unique column. SQL Server allows only one. PostgreSQL 15+ has `UNIQUE NULLS NOT DISTINCT` to allow only one.
- A `CHECK` passes when its condition is NULL. `CHECK (price > 0)` accepts a NULL price; add `NOT NULL` too.

## Interview questions

1. **Primary key vs unique key?** One PK per table, never NULL, usually the clustered index (SQL Server/MySQL). Many unique keys, NULLs allowed.
2. **Can a table have no primary key?** Technically yes, but it's almost always a mistake: duplicates become possible and rows can't be referenced reliably.
3. **What is a composite key?** A key made of several columns, e.g. `(order_id, product_id)`.
4. **What does ON DELETE CASCADE do? When is it dangerous?** Deleting a parent deletes its children. Dangerous when one accidental delete wipes out large amounts of related data.
5. **Surrogate vs natural key?** Surrogate: generated, meaningless, stable (`id`). Natural: real-world value (email, ISBN); can change and may not be truly unique. Common practice: surrogate PK + `UNIQUE` on the natural key.
6. **Does a foreign key create an index?** In MySQL (InnoDB), yes. In PostgreSQL, Oracle and SQL Server, no; create one yourself.
7. **What is referential integrity?** Every foreign key value points at an existing row. FKs enforce it.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql)

Next: [03-advanced · Common table expressions](../../03-advanced/01-common-table-expressions/)
