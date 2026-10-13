# 00 · Setup

You need one database server to follow the tutorial. **PostgreSQL is recommended**: all lesson scripts are written for it, it supports every feature covered (window functions, CTEs, MERGE, materialized views, row-level security), and it is free.

| Guide | Use it when |
|---|---|
| [postgres.md](postgres.md) | You are starting out. Every `examples.sql` runs on it unchanged. |
| [mysql.md](mysql.md) | Your job or project uses MySQL. Lessons point out where MySQL differs. |
| [oracle.md](oracle.md) | You're preparing for an Oracle / PL/SQL role. Runs in Docker. |
| [sqlite.md](sqlite.md) | You want zero setup. Good for basics; lacks procedures, permissions and some types. |

## After installing

1. Create a database for the tutorial and load the sample data:

   ```bash
   createdb sqltutorial
   psql -d sqltutorial -f sample-db/schema.sql
   psql -d sqltutorial -f sample-db/seed.sql
   ```

2. Open a lesson, read its `README.md`, then run its `examples.sql`:

   ```bash
   psql -d sqltutorial -f 01-basics/04-select-and-where/examples.sql
   ```

   Running statements one at a time in a GUI client (DBeaver, pgAdmin, VS Code SQLTools) is even better for learning.

3. To check that every lesson still runs (for example after you edit one):

   ```bash
   PGDATABASE=sqltutorial scripts/run-all-postgres.sh
   ```

## SQL categories (you will see these names everywhere)

| Category | Meaning | Statements |
|---|---|---|
| DDL – Data Definition | Define structure | `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `RENAME` |
| DML – Data Manipulation | Change rows | `INSERT`, `UPDATE`, `DELETE`, `MERGE` |
| DQL – Data Query | Read rows | `SELECT` |
| DCL – Data Control | Permissions | `GRANT`, `REVOKE` |
| TCL – Transaction Control | Group changes | `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT` |
