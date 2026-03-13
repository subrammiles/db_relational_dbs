# Login to MySQL shell

sudo mysql

CREATE DATABASE mydatabase;
SHOW DATABASES;



mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mydatabase         |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.00 sec)


When you install MySQL, it automatically creates several system databases. These are used internally by MySQL for configuration, performance monitoring, and metadata. You normally do not modify them manually.

You saw:

information_schema
mydatabase
mysql
performance_schema
sys

mydatabase is the one you created. The others are system databases.

mysql Database

This is the most important system database.

It stores user accounts and permissions.

Typical tables inside it:

user → MySQL users and authentication

db → database-level permissions

tables_priv → table permissions

columns_priv → column permissions

Example:

SELECT User, Host FROM mysql.user;

This shows all MySQL users.

You usually manage this database using commands like:

CREATE USER
GRANT
REVOKE

instead of editing tables directly.

2. information_schema

This database contains metadata about all databases, tables, and columns.

It does not store real data, only information about the structure of databases.

Example tables:

TABLES

COLUMNS

SCHEMATA

STATISTICS

Example query:

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'mydatabase';

This lists tables in mydatabase.

Think of it as a database describing your databases.

3. performance_schema

This database is used for monitoring MySQL performance.

It tracks:

query execution

memory usage

locks

threads

I/O operations

Example:

SELECT * FROM performance_schema.threads;

This helps DBAs debug slow queries or performance issues.

4. sys

sys is a helper database built on top of performance_schema.

It provides simpler views for performance monitoring.

Instead of complex performance queries, you can run easier ones.

Example:

SELECT * FROM sys.host_summary;

This gives summarized server statistics.

Think of sys as a user-friendly interface for performance_schema.