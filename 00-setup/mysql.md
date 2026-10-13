# MySQL setup (Ubuntu)

## 1. Install

```bash
sudo apt update
sudo apt install mysql-server
sudo systemctl status mysql
```

## 2. Secure the installation

```bash
sudo mysql_secure_installation
```

It asks you to set a root password policy, remove anonymous users, disallow remote root login and remove the test database. Answer **Y** to most prompts. The script ships with MySQL itself, so it works on any Linux distribution.

## 3. Create a database and a user

```bash
sudo mysql
```

```sql
CREATE DATABASE sqltutorial;
SHOW DATABASES;

CREATE USER 'testuser1'@'localhost' IDENTIFIED BY 'testpassword';
GRANT ALL PRIVILEGES ON sqltutorial.* TO 'testuser1'@'localhost';
FLUSH PRIVILEGES;   -- only needed if you edit the grant tables directly; harmless here
```

Log in as that user:

```bash
mysql -u testuser1 -p sqltutorial
```

## 4. Load the sample database

`schema.sql` uses `DROP TABLE ... CASCADE`, which MySQL ignores with a warning, and a PostgreSQL `SET` on line 1 that MySQL rejects. Strip that line first:

```bash
sed '1d' sample-db/schema.sql | mysql -u testuser1 -p sqltutorial
mysql -u testuser1 -p sqltutorial < sample-db/seed.sql
```

## Running the lesson `mysql.sql` files

Those files are self-contained: they create their own small tables, and some reuse names like `employees` or `customers` and `DROP` them first. **Run them in a scratch database, not in `sqltutorial`**, so they can't overwrite the sample data:

```bash
mysql -u testuser1 -p -e "CREATE DATABASE IF NOT EXISTS scratch"
mysql -u testuser1 -p scratch < 03-advanced/07-triggers/mysql.sql
```

(Grant the user access to `scratch` first: `GRANT ALL PRIVILEGES ON scratch.* TO 'testuser1'@'localhost';`. Some files also create `testDB` or `joinDB`.)

## The system databases

`SHOW DATABASES` lists several databases you did not create. Don't modify them by hand.

| Database | Holds | Example |
|---|---|---|
| `mysql` | User accounts and privileges (`user`, `db`, `tables_priv`, `columns_priv`) | `SELECT User, Host FROM mysql.user;` |
| `information_schema` | Metadata about every database, table and column (standard SQL; PostgreSQL has it too) | `SELECT table_name FROM information_schema.tables WHERE table_schema = 'sqltutorial';` |
| `performance_schema` | Low-level monitoring: query execution, memory, locks, threads, I/O | `SELECT * FROM performance_schema.threads;` |
| `sys` | Friendly views on top of `performance_schema` | `SELECT * FROM sys.host_summary;` |

Manage users with `CREATE USER`, `GRANT` and `REVOKE` rather than editing `mysql.*` tables.

## mysql client cheat sheet

| Command | Does |
|---|---|
| `SHOW DATABASES;` | List databases |
| `USE db;` | Switch database |
| `SHOW TABLES;` | List tables |
| `DESCRIBE t;` | Columns of a table |
| `SHOW CREATE TABLE t\G` | Full DDL, vertical output |
| `SHOW INDEX FROM t;` | Indexes |
| `SOURCE file.sql;` | Run a file |
