-- 02 · CREATE TABLE in SQL Server (T-SQL)

DROP TABLE IF EXISTS users;          -- SQL Server 2016+
CREATE TABLE users (
    user_id     INT IDENTITY(1,1) PRIMARY KEY,         -- auto-increment: seed 1, step 1
    name        NVARCHAR(100) NOT NULL,                -- N = Unicode
    email       VARCHAR(100)  UNIQUE,
    balance     DECIMAL(10,2) DEFAULT 0,
    is_active   BIT           DEFAULT 1,               -- no BOOLEAN type
    birth_date  DATE,
    created_at  DATETIME2     DEFAULT SYSDATETIME(),
    user_guid   UNIQUEIDENTIFIER DEFAULT NEWID()
);

INSERT INTO users (name) VALUES (N'Subbu');
SELECT * FROM users;

-- Describe the table
EXEC sp_help 'users';
SELECT name, TYPE_NAME(system_type_id) AS type, max_length, is_nullable
FROM sys.columns WHERE object_id = OBJECT_ID('users');

-- Copy a table with data: SELECT ... INTO (SQL Server's CTAS)
SELECT emp_id, first_name, salary
INTO high_paid
FROM employees
WHERE salary > 100000;
SELECT * FROM high_paid;

-- Temporary tables: #local lives for the session, ##global for everyone until the creator disconnects
CREATE TABLE #scratch (n INT);
INSERT INTO #scratch VALUES (1), (2);
SELECT * FROM #scratch;

-- Table variable: scoped to the batch
DECLARE @t TABLE (n INT);
INSERT INTO @t VALUES (10);
SELECT * FROM @t;

-- List tables
SELECT name FROM sys.tables ORDER BY name;

DROP TABLE #scratch;
DROP TABLE high_paid;
DROP TABLE users;
