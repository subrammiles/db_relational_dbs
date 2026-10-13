# 08 · UPDATE and DELETE

## UPDATE

```sql
UPDATE table_name
SET column1 = value1, column2 = value2
WHERE condition;
```

- **Without `WHERE`, every row is updated.** Run the same `WHERE` as a `SELECT` first to see what will change.
- The right-hand side can use the current value: `SET salary = salary * 1.10`.
- All `SET` expressions see the **old** row values, so `SET a = b, b = a` swaps the two columns (except in MySQL, which applies them left to right).

### Updating from another table

| Database | Syntax |
|---|---|
| PostgreSQL | `UPDATE e SET ... FROM other o WHERE o.id = e.id` |
| MySQL | `UPDATE e JOIN other o ON o.id = e.id SET ...` |
| SQL Server | `UPDATE e SET ... FROM e JOIN other o ON ...` |
| Oracle / standard | `UPDATE e SET col = (SELECT ... FROM other o WHERE o.id = e.id) WHERE EXISTS (...)`, or `MERGE` |

## DELETE

```sql
DELETE FROM table_name WHERE condition;
```

- **Without `WHERE`, every row is deleted.**
- Rows referenced by a foreign key can't be deleted unless the FK says `ON DELETE CASCADE` / `SET NULL` (see [constraints](../../02-intermediate/08-constraints-and-keys/)).
- PostgreSQL: `DELETE ... USING other_table WHERE ...` to delete based on a join; MySQL: `DELETE t FROM t JOIN ...`.
- `RETURNING *` (PostgreSQL, SQLite, Oracle 23c) shows the rows you changed or removed.

## DELETE vs TRUNCATE vs DROP

| | `DELETE` | `TRUNCATE` | `DROP` |
|---|---|---|---|
| Type | DML | DDL | DDL |
| Removes | Chosen rows (`WHERE`) | All rows | The whole table (structure + data + indexes) |
| Speed on big tables | Slow (row by row, logged) | Very fast (deallocates pages) | Fast |
| Fires row triggers | Yes | No | No |
| Rollback | Yes | PostgreSQL / SQL Server: yes inside a transaction. Oracle / MySQL: no (auto-commits) | Same as TRUNCATE |
| Resets identity | No | Yes (MySQL, SQL Server; PostgreSQL with `RESTART IDENTITY`) | — |
| Blocked by FKs pointing at it | Only for referenced rows | Yes (PostgreSQL: `TRUNCATE ... CASCADE`) | Yes (`CASCADE` / `CASCADE CONSTRAINTS`) |

## Soft delete

Many applications never `DELETE`; they set `deleted_at = CURRENT_TIMESTAMP` and filter `WHERE deleted_at IS NULL`. It keeps history and makes undo easy, at the cost of every query needing the filter (a view helps).

## Safety habits

1. Write the `SELECT` with your `WHERE`, check the rows, then change `SELECT *` to `UPDATE`/`DELETE`.
2. Wrap risky changes in a transaction: `BEGIN; UPDATE ...; SELECT ...;` then `COMMIT` or `ROLLBACK`.
3. MySQL Workbench's *safe updates* mode blocks `UPDATE`/`DELETE` without a key in `WHERE`.

## Interview questions

1. **DELETE vs TRUNCATE vs DROP?** See the table above. The short answer: DELETE removes chosen rows and can be rolled back; TRUNCATE empties the table quickly as DDL; DROP removes the table itself.
2. **How do you delete duplicate rows but keep one?** Number the duplicates with `ROW_NUMBER() OVER (PARTITION BY the_columns ORDER BY id)` and delete where the number > 1. See [interview problems](../../04-interview/).
3. **How do you update a table using values from another table?** `UPDATE ... FROM` (PostgreSQL), `UPDATE ... JOIN` (MySQL), correlated subquery or `MERGE` (Oracle).
4. **How do you swap two column values?** `UPDATE t SET a = b, b = a;` (not in MySQL, which needs a temporary variable or column).

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [mysql.sql](mysql.sql) · [oracle.sql](oracle.sql)

Next: [09 · ALTER, DROP and TRUNCATE](../09-alter-drop-truncate/)
