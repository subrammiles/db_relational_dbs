-- 06 · Stored procedures and functions in SQL Server (T-SQL)
-- CREATE PROCEDURE / FUNCTION must be the first statement in a batch, hence the GO lines.

DROP PROCEDURE IF EXISTS dbo.transfer;
DROP PROCEDURE IF EXISTS dbo.dept_stats;
DROP FUNCTION IF EXISTS dbo.annual_salary;
DROP FUNCTION IF EXISTS dbo.customer_orders;
GO

-- Scalar function
CREATE FUNCTION dbo.annual_salary (@emp_id INT)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @s DECIMAL(12,2);
    SELECT @s = salary FROM employees WHERE emp_id = @emp_id;
    RETURN @s * 12;
END;
GO

-- Inline table-valued function: like a parameterised view (fast, gets inlined)
CREATE FUNCTION dbo.customer_orders (@customer_id INT)
RETURNS TABLE
AS
RETURN (
    SELECT o.order_id, o.order_date, o.status, SUM(oi.quantity * oi.unit_price) AS total
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.customer_id = @customer_id
    GROUP BY o.order_id, o.order_date, o.status
);
GO

-- Procedure with validation, a transaction and error handling
CREATE PROCEDURE dbo.transfer
    @from INT, @to INT, @amount DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;          -- suppress "n rows affected" messages
    SET XACT_ABORT ON;

    IF @amount <= 0 THROW 50001, 'Amount must be positive', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE accounts SET balance = balance - @amount WHERE account_id = @from;
        IF @@ROWCOUNT = 0 THROW 50002, 'Source account not found', 1;

        UPDATE accounts SET balance = balance + @amount WHERE account_id = @to;
        IF @@ROWCOUNT = 0 THROW 50003, 'Target account not found', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- OUTPUT parameters
CREATE PROCEDURE dbo.dept_stats
    @dept_id INT, @headcount INT OUTPUT, @avg_salary DECIMAL(12,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @headcount = COUNT(*), @avg_salary = AVG(salary) FROM employees WHERE dept_id = @dept_id;
END;
GO

-- Use them
SELECT first_name, dbo.annual_salary(emp_id) AS annual FROM employees WHERE dept_id = 4;
SELECT * FROM dbo.customer_orders(1);

-- APPLY a table-valued function per row
SELECT c.name, t.order_id, t.total
FROM customers c
CROSS APPLY dbo.customer_orders(c.customer_id) t
WHERE c.country = 'UK';

EXEC dbo.transfer @from = 1, @to = 3, @amount = 1500;
SELECT * FROM accounts;

BEGIN TRY
    EXEC dbo.transfer @from = 2, @to = 99, @amount = 100;
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE() AS failed;
END CATCH;

DECLARE @n INT, @avg DECIMAL(12,2);
EXEC dbo.dept_stats @dept_id = 1, @headcount = @n OUTPUT, @avg_salary = @avg OUTPUT;
SELECT @n AS headcount, @avg AS avg_salary;

-- Dynamic SQL done safely: sp_executesql with parameters, QUOTENAME for identifiers
DECLARE @table SYSNAME = N'orders', @min INT = 10, @sql NVARCHAR(MAX), @count INT;
SET @sql = N'SELECT @cnt = COUNT(*) FROM ' + QUOTENAME(@table) + N' WHERE order_id >= @min_id';
EXEC sp_executesql @sql, N'@min_id INT, @cnt INT OUTPUT', @min_id = @min, @cnt = @count OUTPUT;
SELECT @count AS orders_from_10;

-- Put balances back and clean up
UPDATE accounts SET balance = CASE account_id WHEN 1 THEN 5000 WHEN 2 THEN 2000 ELSE 0 END;
DROP PROCEDURE dbo.dept_stats;
DROP PROCEDURE dbo.transfer;
DROP FUNCTION dbo.customer_orders;
DROP FUNCTION dbo.annual_salary;
