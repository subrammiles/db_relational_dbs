-- 05 · Transactions and error handling in SQL Server (T-SQL)

SELECT * FROM accounts;

-- ---------------------------------------------------------------
-- The robust pattern: XACT_ABORT + TRY/CATCH
-- ---------------------------------------------------------------
-- Without XACT_ABORT, many errors only abort the failing STATEMENT and the
-- transaction carries on. XACT_ABORT ON makes any error roll back the whole transaction.
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 1000 WHERE account_id = 2;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;     -- re-raise to the caller
END CATCH;

SELECT * FROM accounts;      -- Alice 4000, Bob 3000

-- A transfer that violates CHECK (balance >= 0): nothing is applied
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE accounts SET balance = balance + 9999 WHERE account_id = 3;
    UPDATE accounts SET balance = balance - 9999 WHERE account_id = 2;   -- fails
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT ERROR_NUMBER() AS error_number, ERROR_MESSAGE() AS error_message;
END CATCH;

SELECT * FROM accounts;      -- Carol still 0

-- Zero rows updated is not an error: check @@ROWCOUNT
BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE account_id = 99;
    IF @@ROWCOUNT = 0 THROW 50001, 'Target account does not exist', 1;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT ERROR_MESSAGE() AS rolled_back_because;
END CATCH;

-- Savepoints: SAVE TRANSACTION
BEGIN TRANSACTION;
UPDATE accounts SET balance = balance + 100 WHERE account_id = 3;
SAVE TRANSACTION bonus;
UPDATE accounts SET balance = balance + 100000 WHERE account_id = 3;
ROLLBACK TRANSACTION bonus;
COMMIT TRANSACTION;
SELECT * FROM accounts WHERE account_id = 3;     -- 100

-- Isolation levels. SQL Server's default READ COMMITTED uses locks (readers can block
-- behind writers) unless the database has READ_COMMITTED_SNAPSHOT ON (row versioning).
SELECT name, is_read_committed_snapshot_on, snapshot_isolation_state_desc
FROM sys.databases WHERE name = DB_NAME();

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
SELECT SUM(balance) AS total FROM accounts;
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Pessimistic locking uses table hints instead of FOR UPDATE
BEGIN TRANSACTION;
SELECT balance FROM accounts WITH (UPDLOCK, ROWLOCK) WHERE account_id = 1;
UPDATE accounts SET balance = balance - 1 WHERE account_id = 1;
ROLLBACK;

-- WITH (NOLOCK) = READ UNCOMMITTED for that table: dirty reads. Common in legacy code; avoid.

-- Put the balances back
UPDATE accounts SET balance = CASE account_id WHEN 1 THEN 5000 WHEN 2 THEN 2000 ELSE 0 END;
SET XACT_ABORT OFF;
