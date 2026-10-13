# 11 · Upsert and MERGE

**Upsert** = insert a row, or update it if it already exists. It's needed for syncing data, counters, "save settings", idempotent imports, etc.

## Why not "SELECT, then INSERT or UPDATE"?

Two sessions can both `SELECT`, both see "not found", and both `INSERT`: one fails with a duplicate key error (or, without a unique constraint, you get duplicates). The built-in upsert statements are **atomic** and rely on a **unique constraint/index** to detect the conflict.

## Syntax by database

| Database | Statement |
|---|---|
| PostgreSQL 9.5+ | `INSERT ... ON CONFLICT (key) DO UPDATE SET col = EXCLUDED.col` / `DO NOTHING` |
| PostgreSQL 15+ | `MERGE` (standard) |
| MySQL | `INSERT ... ON DUPLICATE KEY UPDATE col = VALUES(col)` (8.0.19+: `AS new ... col = new.col`); `INSERT IGNORE`; `REPLACE INTO` (delete + insert!) |
| Oracle | `MERGE INTO ... USING ... ON (...) WHEN MATCHED THEN UPDATE ... WHEN NOT MATCHED THEN INSERT ...` |
| SQL Server | `MERGE` (has known concurrency caveats; many teams use `UPDATE` + `INSERT ... WHERE NOT EXISTS` with locking hints) |
| SQLite 3.24+ | `INSERT ... ON CONFLICT (key) DO UPDATE SET ... = excluded....` |

### PostgreSQL ON CONFLICT

```sql
INSERT INTO products (product_id, product_name, category, price, stock)
VALUES (2, 'Wireless Mouse', 'Electronics', 750, 50)
ON CONFLICT (product_id)
DO UPDATE SET price = EXCLUDED.price,               -- EXCLUDED = the row you tried to insert
              stock = products.stock + EXCLUDED.stock
WHERE products.price <> EXCLUDED.price OR EXCLUDED.stock > 0;
```

### MERGE (standard SQL)

```sql
MERGE INTO target t
USING source s
ON t.id = s.id
WHEN MATCHED AND s.deleted THEN DELETE
WHEN MATCHED THEN UPDATE SET price = s.price
WHEN NOT MATCHED THEN INSERT (id, price) VALUES (s.id, s.price);
```

`MERGE` syncs a whole source set (a staging table, a query) into a target in one statement, and can also delete. Each target row may be matched by **at most one** source row, or you get an error.

## Pitfalls

- MySQL's `REPLACE INTO` **deletes** the old row and inserts a new one: it fires delete triggers, cascades `ON DELETE` to children, and resets columns you didn't specify.
- `ON DUPLICATE KEY UPDATE` fires on **any** unique key conflict, not only the one you had in mind.
- `INSERT IGNORE` also silences other errors (bad data becomes warnings).
- Upserts need a unique constraint on the conflict columns; without it, PostgreSQL rejects `ON CONFLICT (col)`.

## Interview questions

1. **What is an upsert and how do you do it in PostgreSQL / MySQL / Oracle?** See the table.
2. **Why is check-then-insert unsafe?** Race condition between the check and the insert under concurrency.
3. **What does EXCLUDED mean?** In `ON CONFLICT DO UPDATE`, the row that was proposed for insertion.
4. **MERGE vs ON CONFLICT?** MERGE takes an arbitrary source set and supports UPDATE/INSERT/DELETE branches; ON CONFLICT is per inserted row, conflict detection via a unique index, and is concurrency-safe.
5. **REPLACE INTO vs ON DUPLICATE KEY UPDATE?** REPLACE deletes then inserts (side effects); ON DUPLICATE KEY updates in place.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [mysql.sql](mysql.sql) · [oracle.sql](oracle.sql) · [sqlserver.sql](sqlserver.sql)

Next: [12 · Pivot and advanced grouping](../12-pivot-and-advanced-grouping/)
