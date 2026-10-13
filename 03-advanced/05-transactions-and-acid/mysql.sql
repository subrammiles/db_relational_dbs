-- 05 · Transactions and ACID in MySQL (InnoDB)
--
-- ACID describes the four properties that guarantee reliable transactions.
-- A transaction is a group of SQL operations that behave as one logical unit of work.
--   A - Atomicity   : all or nothing; if one operation fails the whole transaction is rolled back
--   C - Consistency : the database moves from one valid state to another
--   I - Isolation   : concurrent transactions don't interfere; each behaves as if it runs alone
--   D - Durability  : once committed, data survives crashes and power failures

CREATE DATABASE IF NOT EXISTS mydatabase;
USE mydatabase;

DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
    account_id  INT PRIMARY KEY,                 -- unique account number
    name        VARCHAR(50),                     -- account holder
    balance     INT CHECK (balance >= 0)         -- no negative balances (consistency rule, MySQL 8.0.16+)
);

INSERT INTO accounts (account_id, name, balance) VALUES
    (1, 'Alice', 5000),
    (2, 'Bob',   2000);

-- ---------------------------------------------------------------
-- A successful transfer
-- ---------------------------------------------------------------
START TRANSACTION;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 2;
COMMIT;

SELECT * FROM accounts;   -- Alice 4000, Bob 3000

-- ---------------------------------------------------------------
-- Atomicity
-- Note: updating a non-existent account is NOT an error in SQL; it just affects 0 rows.
-- The application (or a stored procedure) must notice ROW_COUNT() = 0 and roll back.
-- ---------------------------------------------------------------
START TRANSACTION;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 99;
SELECT ROW_COUNT() AS rows_changed;          -- 0 -> the transfer target is missing
ROLLBACK;                                    -- so we undo the debit as well

SELECT * FROM accounts;   -- unchanged: Alice 4000, Bob 3000

-- ---------------------------------------------------------------
-- Consistency: the CHECK rejects a negative balance
-- ---------------------------------------------------------------
-- UPDATE accounts SET balance = -500 WHERE account_id = 1;
-- ERROR 3819 (HY000): Check constraint 'accounts_chk_1' is violated.
--
-- In MySQL a failed statement does NOT abort the transaction: earlier statements
-- in the same transaction are still pending, and you must ROLLBACK yourself.

-- ---------------------------------------------------------------
-- Isolation: InnoDB's default is REPEATABLE READ
-- ---------------------------------------------------------------
SELECT @@transaction_isolation;
-- Session 1: START TRANSACTION; UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
-- Session 2: SELECT balance FROM accounts WHERE account_id = 1;   -- still 4000: uncommitted changes are invisible
-- This prevents double spending and incorrect balances.

-- ---------------------------------------------------------------
-- Durability: after COMMIT the change is in the redo log on disk.
-- Even if the server crashes or restarts, the balances stay
--   Alice 4000, Bob 3000
-- ---------------------------------------------------------------

-- Savepoints
START TRANSACTION;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;
SAVEPOINT sp1;
UPDATE accounts SET balance = 0 WHERE account_id = 2;
ROLLBACK TO SAVEPOINT sp1;
COMMIT;

SELECT * FROM accounts;   -- Bob 3100

-- DDL causes an implicit COMMIT in MySQL:
START TRANSACTION;
UPDATE accounts SET balance = balance + 1 WHERE account_id = 1;
CREATE TABLE implicit_commit_demo (id INT);   -- commits the UPDATE above!
ROLLBACK;                                      -- too late, nothing to roll back
SELECT * FROM accounts WHERE account_id = 1;  -- 4001
DROP TABLE implicit_commit_demo;

DROP TABLE accounts;
