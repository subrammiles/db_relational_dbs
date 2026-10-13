# 07 · Triggers

A trigger is code that runs **automatically** when a specific event happens on a table.

| Part | Options |
|---|---|
| Event | `INSERT`, `UPDATE` (optionally `UPDATE OF column`), `DELETE`, `TRUNCATE` (PG) |
| Timing | `BEFORE`, `AFTER`, `INSTEAD OF` (views) |
| Granularity | `FOR EACH ROW` (once per affected row) or `FOR EACH STATEMENT` (once per statement) |
| Condition | `WHEN (NEW.salary <> OLD.salary)` (PostgreSQL, Oracle) |

| Timing + event | Typical use |
|---|---|
| `BEFORE INSERT` / `BEFORE UPDATE` | Fill or normalise values (`updated_at = now()`, lower-case emails), complex validation |
| `AFTER INSERT` / `AFTER UPDATE` / `AFTER DELETE` | Audit logs, maintaining summary tables, notifications |
| `INSTEAD OF` | Make a complex view writable |

## OLD and NEW

| Event | `OLD` | `NEW` |
|---|---|---|
| INSERT | — | the row being inserted |
| UPDATE | row before the change | row after the change |
| DELETE | the row being deleted | — |

In a `BEFORE ROW` trigger you can **modify `NEW`** to change what gets stored, or abort by raising an error. (Oracle writes `:NEW` / `:OLD` inside the body.)

## Syntax by database

| | PostgreSQL | MySQL | Oracle |
|---|---|---|---|
| Body | Separate function `RETURNS trigger`, then `CREATE TRIGGER ... EXECUTE FUNCTION f()` | Inline `BEGIN ... END` | Inline `BEGIN ... END;` |
| Statement-level | ✔ (with transition tables) | ✘ row only | ✔ |
| Several per event | ✔ (alphabetical order) | ✔ (`FOLLOWS` / `PRECEDES`) | ✔ (`FOLLOWS`) |
| Abort | `RAISE EXCEPTION` | `SIGNAL SQLSTATE '45000'` | `RAISE_APPLICATION_ERROR` |

## Use triggers carefully

- **Hidden logic:** someone running an `UPDATE` doesn't see that 3 other tables change. Document triggers well.
- **Performance:** row triggers run per row; a bulk update of a million rows fires a million times.
- **Cascading triggers** (trigger updates a table that has its own trigger) get hard to reason about.
- Oracle raises **ORA-04091 "mutating table"** if a row trigger queries the table it's defined on.
- `TRUNCATE` and bulk loaders may bypass row triggers.

Prefer **constraints** for rules they can express (`CHECK`, `FOREIGN KEY`, `UNIQUE`), **generated columns** for derived values, and application code for business workflows. Triggers shine for audit trails and keeping denormalised data in sync.

## Interview questions

1. **What is a trigger? Give a use case.** Code that runs automatically on INSERT/UPDATE/DELETE; e.g. writing an audit row whenever a salary changes.
2. **BEFORE vs AFTER trigger?** BEFORE runs before the row is written and can change or reject it; AFTER runs once the change is applied, typically to propagate it elsewhere.
3. **Row-level vs statement-level?** Row-level fires once per affected row with OLD/NEW; statement-level fires once per statement regardless of row count.
4. **What are OLD and NEW?** Pseudo-records holding the row before and after the change.
5. **What is an INSTEAD OF trigger?** A trigger on a view that replaces the DML with your own logic against the base tables.
6. **Triggers vs constraints?** Constraints are declarative, faster and always enforced; use triggers only for what constraints can't express.
7. **What is the mutating table error?** Oracle error when a row-level trigger reads or modifies the table that fired it.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [mysql.sql](mysql.sql) · [oracle.sql](oracle.sql)

Next: [08 · Cursors](../08-cursors/)
