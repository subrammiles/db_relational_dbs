-- 05 · Transactions and ACID (PostgreSQL)
-- accounts: Alice (1) 5000, Bob (2) 2000, Carol (3) 0. balance has CHECK (balance >= 0).

SELECT * FROM accounts ORDER BY account_id;

-- ---------------------------------------------------------------
-- 1. A successful transfer: both updates are committed together
-- ---------------------------------------------------------------
BEGIN;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 2;
COMMIT;

SELECT * FROM accounts ORDER BY account_id;    -- Alice 4000, Bob 3000

-- ---------------------------------------------------------------
-- 2. Atomicity: ROLLBACK undoes everything since BEGIN
-- ---------------------------------------------------------------
BEGIN;
UPDATE accounts SET balance = balance - 500 WHERE account_id = 1;
SELECT * FROM accounts WHERE account_id = 1;   -- 3500 inside this transaction
ROLLBACK;
SELECT * FROM accounts WHERE account_id = 1;   -- back to 4000

-- ---------------------------------------------------------------
-- 3. Consistency: the CHECK constraint makes the whole transfer fail.
--    In PostgreSQL an error aborts the transaction; nothing is applied.
--    (The DO block catches the error so this script can continue.)
-- ---------------------------------------------------------------
DO $$
BEGIN
    UPDATE accounts SET balance = balance + 9999 WHERE account_id = 3;   -- Carol receives...
    UPDATE accounts SET balance = balance - 9999 WHERE account_id = 2;   -- ...but Bob can't afford it
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'Transfer rejected and rolled back: %', SQLERRM;
END $$;

SELECT * FROM accounts ORDER BY account_id;    -- Carol still 0: the first UPDATE was undone too

-- ---------------------------------------------------------------
-- 4. Zero rows updated is NOT an error. Account 99 doesn't exist,
--    so a naive transfer would lose 1000. Check the row count and abort.
-- ---------------------------------------------------------------
DO $$
DECLARE
    n INT;
BEGIN
    UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 1000 WHERE account_id = 99;
    GET DIAGNOSTICS n = ROW_COUNT;
    IF n = 0 THEN
        RAISE EXCEPTION 'Target account does not exist';    -- undoes the first UPDATE as well
    END IF;
EXCEPTION WHEN raise_exception THEN
    RAISE NOTICE 'Rolled back: %', SQLERRM;
END $$;

SELECT * FROM accounts WHERE account_id = 1;   -- still 4000

-- ---------------------------------------------------------------
-- 5. After an error, PostgreSQL refuses further statements until ROLLBACK:
--    BEGIN;
--    UPDATE accounts SET balance = -1 WHERE account_id = 1;   -- ERROR (check)
--    SELECT 1;   -- ERROR: current transaction is aborted, commands ignored until end of transaction block
--    ROLLBACK;
-- ---------------------------------------------------------------

-- ---------------------------------------------------------------
-- 6. SAVEPOINT: partial rollback
-- ---------------------------------------------------------------
BEGIN;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 3;      -- keep this
SAVEPOINT bonus;
UPDATE accounts SET balance = balance + 100000 WHERE account_id = 3;   -- oops
ROLLBACK TO SAVEPOINT bonus;
COMMIT;
SELECT * FROM accounts WHERE account_id = 3;   -- 100

-- ---------------------------------------------------------------
-- 7. DDL is transactional in PostgreSQL
-- ---------------------------------------------------------------
BEGIN;
CREATE TABLE will_vanish (id INT);
ALTER TABLE accounts ADD COLUMN temp_col INT;
ROLLBACK;
SELECT COUNT(*) AS will_vanish_exists FROM information_schema.tables WHERE table_name = 'will_vanish';   -- 0

-- ---------------------------------------------------------------
-- 8. Locking rows you are about to change (pessimistic locking)
-- ---------------------------------------------------------------
BEGIN;
SELECT balance FROM accounts WHERE account_id IN (1, 2) ORDER BY account_id FOR UPDATE;
-- other sessions trying to UPDATE rows 1 or 2 now wait until we finish
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;
COMMIT;

-- ---------------------------------------------------------------
-- 9. Optimistic locking with a version column
-- ---------------------------------------------------------------
ALTER TABLE accounts ADD COLUMN version INT NOT NULL DEFAULT 1;

-- The app read account 2 at version 1; it writes only if nobody changed it since.
UPDATE accounts SET balance = balance + 50, version = version + 1
WHERE account_id = 2 AND version = 1;          -- 1 row: success

UPDATE accounts SET balance = balance + 50, version = version + 1
WHERE account_id = 2 AND version = 1;          -- 0 rows: someone else won, reload and retry

ALTER TABLE accounts DROP COLUMN version;

-- ---------------------------------------------------------------
-- 10. Isolation level for one transaction
-- ---------------------------------------------------------------
BEGIN ISOLATION LEVEL REPEATABLE READ;
SHOW transaction_isolation;
SELECT SUM(balance) AS total FROM accounts;    -- this snapshot is stable until COMMIT
COMMIT;

SHOW default_transaction_isolation;            -- read committed
