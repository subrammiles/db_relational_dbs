# SQL Server setup (Docker)

Microsoft SQL Server runs on Linux in Docker. The Developer edition is free for learning and testing.

## 1. Run the container

```bash
docker run -d --name sqlserver \
  -e ACCEPT_EULA=Y \
  -e MSSQL_SA_PASSWORD='Tutorial#2026' \
  -p 1433:1433 \
  mcr.microsoft.com/mssql/server:2022-latest
```

The password must be at least 8 characters with upper case, lower case, digits and symbols, or the container exits. Check with `docker logs sqlserver`.

## 2. Connect with sqlcmd

```bash
docker exec -it sqlserver /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P 'Tutorial#2026'
```

`-C` trusts the container's self-signed certificate. In `sqlcmd`, a statement only runs when you type **`GO`** on its own line.

GUI options: Azure Data Studio, VS Code with the *SQL Server (mssql)* extension, DBeaver, or SSMS on Windows.

## 3. Create a database and a login

```sql
CREATE DATABASE sqltutorial;
GO
CREATE LOGIN tutorial WITH PASSWORD = 'Tutorial#User1';
GO
USE sqltutorial;
CREATE USER tutorial FOR LOGIN tutorial;     -- a login is server-level, a user is per database
ALTER ROLE db_owner ADD MEMBER tutorial;
GO
```

## 4. Load the sample database

`schema.sql` starts with a PostgreSQL-only `SET` and uses `DROP TABLE ... CASCADE`, which T-SQL doesn't have. Filter those out; everything else, including `seed.sql`, runs unchanged:

```bash
grep -v '^SET ' sample-db/schema.sql | sed 's/ CASCADE;/;/' > /tmp/schema_mssql.sql
docker cp /tmp/schema_mssql.sql sqlserver:/tmp/
docker cp sample-db/seed.sql sqlserver:/tmp/
docker exec sqlserver /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P 'Tutorial#2026' -d sqltutorial -i /tmp/schema_mssql.sql
docker exec sqlserver /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P 'Tutorial#2026' -d sqltutorial -i /tmp/seed.sql
```

Unlike the MySQL and Oracle lesson files, the `sqlserver.sql` files run **against the sample database** and leave it unchanged (they roll back or clean up). Run a lesson's T-SQL file the same way: `docker cp 01-basics/06-sorting-and-pagination/sqlserver.sql sqlserver:/tmp/` then `sqlcmd ... -d sqltutorial -i /tmp/sqlserver.sql`.

## T-SQL habits to know

| Topic | T-SQL |
|---|---|
| Batches | `GO` separates batches (a client command, not SQL). `CREATE PROCEDURE/FUNCTION/TRIGGER/VIEW` must be the first statement in its batch. |
| Statement terminator | `;` is optional but recommended (and required before `WITH` CTEs and `MERGE`). |
| Top N | `SELECT TOP (5) ...` or `ORDER BY ... OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY` |
| Auto ids | `INT IDENTITY(1,1)`; read with `SCOPE_IDENTITY()` or `OUTPUT inserted.id` |
| String concat | `+` (NULL makes it NULL) or `CONCAT()` (treats NULL as '') |
| Unicode text | `NVARCHAR`, literals `N'text'` |
| Booleans | `BIT` (0/1); no `TRUE`/`FALSE` literals in older versions |
| NULL replace | `ISNULL(a, b)` or standard `COALESCE` |
| Current time | `GETDATE()`, `SYSDATETIME()`, `GETUTCDATE()` |
| Temp tables | `#local` (session), `##global`; table variables `DECLARE @t TABLE (...)` |
| Variables | `DECLARE @x INT = 5; SET @x = 6; SELECT @x = COUNT(*) FROM t;` |
| Autocommit | On; use `BEGIN TRAN ... COMMIT` |
| Identifiers | `[Square Brackets]` or `"double quotes"` |
| UNIQUE and NULL | A `UNIQUE` column allows only **one** NULL (PostgreSQL/MySQL/Oracle allow many). Use a filtered unique index `WHERE col IS NOT NULL` for the usual behaviour. |
| Case sensitivity | Depends on collation; the default (`SQL_Latin1_General_CP1_CI_AS`) is case-insensitive |
| Metadata | `sp_help 'employees'`, `sys.tables`, `sys.columns`, `INFORMATION_SCHEMA.*` |
