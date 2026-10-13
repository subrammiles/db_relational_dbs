# 05 · Transactions, ACID, isolation and locking

A **transaction** is a group of statements that succeed or fail **as one unit**.

```sql
BEGIN;                                   -- MySQL: START TRANSACTION; Oracle: implicit
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 2;
COMMIT;                                  -- make it permanent (or ROLLBACK to undo)
```

## ACID

| Property | Meaning | Bank transfer example | How databases provide it |
|---|---|---|---|
| **Atomicity** | All or nothing | Money never leaves Alice without reaching Bob | Undo log / rollback segments |
| **Consistency** | Every commit moves the database from one valid state to another; constraints always hold | `CHECK (balance >= 0)` can't be broken | Constraints, triggers, cascades |
| **Isolation** | Concurrent transactions don't see each other's half-finished work | Bob's balance check doesn't see the transfer mid-flight | Locks and/or MVCC |
| **Durability** | Once committed, it survives a crash or power loss | After `COMMIT`, the transfer is permanent | Write-ahead log (WAL / redo log) flushed to disk at commit |

### Atomicity in practice

A transaction is rolled back when you say `ROLLBACK`, when the session disconnects before `COMMIT`, or (in PostgreSQL) automatically after any error. In MySQL and Oracle, a failing **statement** is undone but the transaction stays open: your application must decide to `ROLLBACK`.

Note that an `UPDATE` that matches **zero rows is not an error**. If the second update in a transfer hits a non-existent account, nothing fails. Check the affected row count in your application (or use a stored procedure that raises an error) and roll back yourself.

## Autocommit

| Database | Default |
|---|---|
| PostgreSQL, MySQL, SQL Server, SQLite | **Autocommit on**: each statement is its own transaction unless you `BEGIN` |
| Oracle (SQL*Plus, SQL Developer) | **Off**: DML waits for `COMMIT`; disconnecting usually commits (SQL*Plus) |

**DDL:** in Oracle and MySQL, `CREATE`/`ALTER`/`DROP` **commit** the open transaction implicitly. PostgreSQL and SQL Server DDL is transactional and can be rolled back.

## Savepoints

Partial rollback inside a transaction:

```sql
BEGIN;
INSERT ...;
SAVEPOINT before_risky;
UPDATE ...;
ROLLBACK TO SAVEPOINT before_risky;   -- undo only the UPDATE
COMMIT;                               -- the INSERT is kept
```

## Concurrency problems

| Problem | What happens |
|---|---|
| **Dirty read** | T1 reads T2's **uncommitted** change; T2 rolls back; T1 used data that never existed |
| **Non-repeatable read** | T1 reads a row twice and gets different values because T2 updated and committed in between |
| **Phantom read** | T1 runs the same `WHERE` twice and gets **new rows** inserted by T2 |
| **Lost update** | T1 and T2 both read 100, both add 10, both write 110: one update is lost |
| **Write skew** | Two transactions each check a condition, then write different rows, together breaking the rule (e.g. both doctors go off-call) |

## Isolation levels (SQL standard)

| Level | Dirty read | Non-repeatable read | Phantom |
|---|---|---|---|
| READ UNCOMMITTED | possible | possible | possible |
| **READ COMMITTED** | ✘ | possible | possible |
| **REPEATABLE READ** | ✘ | ✘ | possible (standard) |
| SERIALIZABLE | ✘ | ✘ | ✘ |

| Database | Default | Notes |
|---|---|---|
| PostgreSQL | READ COMMITTED | READ UNCOMMITTED behaves as READ COMMITTED. REPEATABLE READ is snapshot isolation (no phantoms either). SERIALIZABLE is true SSI and may abort with a serialization error that you retry. |
| MySQL InnoDB | **REPEATABLE READ** | Consistent snapshot for plain SELECTs; locking reads use gap/next-key locks to block phantoms |
| Oracle | READ COMMITTED | Only READ COMMITTED and SERIALIZABLE (actually snapshot isolation) |
| SQL Server | READ COMMITTED (locking) | `READ_COMMITTED_SNAPSHOT` / `SNAPSHOT` options switch to row versioning |

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;   -- first statement inside the transaction (PG)
```

## Locking vs MVCC

- **Locking:** readers take shared locks, writers take exclusive locks; readers and writers block each other.
- **MVCC (multi-version concurrency control)** (PostgreSQL, Oracle, MySQL InnoDB): writers create new row versions; readers see a consistent snapshot of older versions. **Readers don't block writers and writers don't block readers.** Two writers on the same row still block.

### Explicit row locks

```sql
SELECT * FROM accounts WHERE account_id = 1 FOR UPDATE;        -- lock rows you're about to change
SELECT ... FOR UPDATE NOWAIT;                                  -- error instead of waiting
SELECT ... FOR UPDATE SKIP LOCKED;                             -- skip locked rows (job queues)
SELECT ... FOR SHARE;                                          -- others can read-lock, not modify
```

### Preventing lost updates

1. **Atomic update:** `UPDATE accounts SET balance = balance - 100 WHERE ...` (not read-then-write in the app).
2. **Pessimistic locking:** `SELECT ... FOR UPDATE`, then update.
3. **Optimistic locking:** keep a `version` column: `UPDATE ... SET ..., version = version + 1 WHERE id = ? AND version = ?`. If 0 rows changed, someone else won; reload and retry.
4. **SERIALIZABLE** isolation + retry on serialization failure.

## Deadlocks

T1 locks row A and wants B; T2 locks B and wants A. Neither can continue. The database detects the cycle and **aborts one** of them (PostgreSQL: `deadlock detected`, MySQL: error 1213, Oracle: ORA-00060).

Avoid them by:

- Touching rows/tables in the **same order** everywhere (e.g. always lock the lower account id first).
- Keeping transactions **short**; never wait for user input inside one.
- Locking everything you need up front (`SELECT ... FOR UPDATE` on all rows at once).
- Using appropriate indexes so updates lock fewer rows (especially in MySQL).
- Retrying the aborted transaction in the application.

[deadlock-demo.md](deadlock-demo.md) walks through causing one with two terminals.

## Interview questions

1. **Explain ACID with an example.** The bank transfer above.
2. **What isolation levels exist and what does each prevent?** See the table.
3. **Default isolation level of PostgreSQL / MySQL / Oracle?** READ COMMITTED / REPEATABLE READ / READ COMMITTED.
4. **What is a dirty read? Phantom read?** See the problems table.
5. **What is MVCC?** Keeping several versions of a row so readers see a consistent snapshot without blocking writers.
6. **What is a deadlock and how do you prevent one?** Circular waiting on locks; consistent lock ordering, short transactions, retries.
7. **COMMIT vs ROLLBACK vs SAVEPOINT?** Make permanent / undo all / mark a point you can undo back to.
8. **Optimistic vs pessimistic locking?** Optimistic: check a version at write time, retry on conflict (good when conflicts are rare). Pessimistic: lock rows when reading (good when conflicts are common).
9. **Is DDL transactional?** PostgreSQL / SQL Server: yes. Oracle / MySQL: no, DDL commits implicitly.
10. **How is durability guaranteed?** The write-ahead log is flushed to disk at commit; after a crash the database replays it.

## Files

- [examples.sql](examples.sql): run in one session
- [deadlock-demo.md](deadlock-demo.md): two-session demos for isolation and deadlocks
- [exercises.sql](exercises.sql)
- [mysql.sql](mysql.sql): the bank transfer in MySQL

Next: [06 · Stored procedures and functions](../06-stored-procedures-and-functions/)
