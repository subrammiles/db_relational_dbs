# Two-session demos: isolation, lost updates and deadlocks

Concurrency only shows up with **two connections**. Open two terminals, connect both to the tutorial database (`psql -d sqltutorial`), and run the steps in order. Reload the sample data first so the balances are Alice 5000, Bob 2000.

## 1. READ COMMITTED: no dirty reads, but non-repeatable reads

| Step | Session A | Session B |
|---|---|---|
| 1 | `BEGIN;` | |
| 2 | `SELECT balance FROM accounts WHERE account_id = 1;` → **5000** | |
| 3 | | `BEGIN;` |
| 4 | | `UPDATE accounts SET balance = 1 WHERE account_id = 1;` |
| 5 | `SELECT balance FROM accounts WHERE account_id = 1;` → **5000** (B's change is uncommitted: no dirty read) | |
| 6 | | `COMMIT;` |
| 7 | `SELECT balance FROM accounts WHERE account_id = 1;` → **1** (same query, new value: non-repeatable read) | |
| 8 | `COMMIT;` | |

Reset: `UPDATE accounts SET balance = 5000 WHERE account_id = 1;`

## 2. REPEATABLE READ: a stable snapshot

Repeat the steps, but start session A with `BEGIN ISOLATION LEVEL REPEATABLE READ;`. Step 7 now still returns **5000**: A keeps seeing the snapshot taken at its first query.

If A then tries `UPDATE accounts SET balance = balance + 1 WHERE account_id = 1;`, PostgreSQL raises
`ERROR: could not serialize access due to concurrent update`: A must roll back and retry. (MySQL instead lets the update proceed on the latest committed row.)

## 3. Lost update, and how to prevent it

The **wrong** way (read in the app, then write a computed value):

| Step | Session A | Session B |
|---|---|---|
| 1 | `BEGIN;` `SELECT balance FROM accounts WHERE account_id = 2;` → 2000 | |
| 2 | | `BEGIN;` `SELECT balance FROM accounts WHERE account_id = 2;` → 2000 |
| 3 | `UPDATE accounts SET balance = 2100 WHERE account_id = 2;` (2000 + 100) | |
| 4 | | `UPDATE accounts SET balance = 2050 WHERE account_id = 2;` (2000 + 50) → **waits** for A's row lock |
| 5 | `COMMIT;` | B's update now runs |
| 6 | | `COMMIT;` → balance is **2050**: A's +100 is lost |

Fixes:

- Let the database do the arithmetic: `UPDATE accounts SET balance = balance + 100 ...`.
- Or lock when reading: `SELECT balance ... FOR UPDATE;` in step 1 and 2. Session B's `SELECT` then waits until A commits and reads 2100.

## 4. Deadlock

| Step | Session A | Session B |
|---|---|---|
| 1 | `BEGIN;` | `BEGIN;` |
| 2 | `UPDATE accounts SET balance = balance - 10 WHERE account_id = 1;` (locks row 1) | |
| 3 | | `UPDATE accounts SET balance = balance - 10 WHERE account_id = 2;` (locks row 2) |
| 4 | `UPDATE accounts SET balance = balance + 10 WHERE account_id = 2;` → **waits** for B | |
| 5 | | `UPDATE accounts SET balance = balance + 10 WHERE account_id = 1;` → waits for A: **cycle** |
| 6 | | After ~1 s (`deadlock_timeout`): `ERROR: deadlock detected`. B's transaction is aborted. |
| 7 | A's update completes. `COMMIT;` | `ROLLBACK;` |

**Prevention:** make every transfer lock the lower `account_id` first. Then both sessions try row 1 first, one waits, and no cycle can form:

```sql
BEGIN;
SELECT * FROM accounts WHERE account_id IN (1, 2) ORDER BY account_id FOR UPDATE;
UPDATE ...;
UPDATE ...;
COMMIT;
```

## 5. Seeing who is waiting on whom (PostgreSQL)

While session B is blocked, run in a third session:

```sql
SELECT pid, state, wait_event_type, pg_blocking_pids(pid) AS blocked_by, query
FROM pg_stat_activity
WHERE datname = current_database() AND pid <> pg_backend_pid();
```

MySQL equivalents: `SHOW ENGINE INNODB STATUS\G` (latest deadlock section) and `performance_schema.data_lock_waits`.
