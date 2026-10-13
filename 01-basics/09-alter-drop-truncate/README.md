# 09 · ALTER, DROP and TRUNCATE

## ALTER TABLE

| Task | PostgreSQL / standard | MySQL | Oracle |
|---|---|---|---|
| Add column | `ADD COLUMN city VARCHAR(50)` | same | `ADD city VARCHAR2(50)` |
| Drop column | `DROP COLUMN city` | same | `DROP COLUMN city` |
| Rename column | `RENAME COLUMN a TO b` | same (8.0+) | same |
| Change type | `ALTER COLUMN c TYPE BIGINT` | `MODIFY c BIGINT` | `MODIFY c NUMBER(19)` |
| Set default | `ALTER COLUMN c SET DEFAULT 0` | same | `MODIFY c DEFAULT 0` |
| Add NOT NULL | `ALTER COLUMN c SET NOT NULL` | `MODIFY c INT NOT NULL` | `MODIFY c NOT NULL` |
| Add constraint | `ADD CONSTRAINT chk CHECK (salary > 0)` | same | same |
| Drop constraint | `DROP CONSTRAINT chk` | `DROP CHECK chk` / `DROP FOREIGN KEY fk` | `DROP CONSTRAINT chk` |
| Rename table | `ALTER TABLE a RENAME TO b` | `RENAME TABLE a TO b` | `RENAME a TO b` |

Adding a `NOT NULL` column to a table that already has rows needs a `DEFAULT` (or fill it first, then add `NOT NULL`).

On big production tables some `ALTER`s rewrite or lock the whole table. Adding a nullable column is cheap almost everywhere; changing a column's type usually isn't.

## DROP

```sql
DROP TABLE employees_backup;
DROP TABLE IF EXISTS employees_backup;       -- no error if missing (Oracle 23c+)
DROP TABLE departments CASCADE;              -- PostgreSQL: also drop FKs/views that depend on it
DROP TABLE departments CASCADE CONSTRAINTS;  -- Oracle: also drop FKs pointing at it
```

Oracle moves dropped tables to the **recycle bin**: `FLASHBACK TABLE t TO BEFORE DROP;` restores it, `DROP TABLE t PURGE` skips the bin.

`DROP` also exists for every other object: `DROP VIEW`, `DROP INDEX`, `DROP DATABASE`, `DROP SCHEMA`, `DROP FUNCTION`...

## TRUNCATE

```sql
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders, order_items RESTART IDENTITY;   -- PostgreSQL: several tables, reset ids
```

Removes all rows instantly while keeping the table. See the DELETE vs TRUNCATE vs DROP table in [lesson 08](../08-update-and-delete/).

## Interview questions

1. **How do you add a NOT NULL column to a table with data?** Give it a default (`ADD COLUMN c INT NOT NULL DEFAULT 0`), or add it nullable, backfill with `UPDATE`, then set `NOT NULL`.
2. **Can you roll back a DROP TABLE?** PostgreSQL and SQL Server: yes, inside a transaction. Oracle: no, but `FLASHBACK TABLE ... TO BEFORE DROP` usually works. MySQL: no.
3. **Why might TRUNCATE fail when DELETE works?** Another table has a foreign key referencing it. TRUNCATE doesn't check rows individually so it refuses outright (unless `CASCADE`).

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [oracle.sql](oracle.sql)

Next: [02-intermediate · Aggregate functions](../../02-intermediate/01-aggregate-functions/)
