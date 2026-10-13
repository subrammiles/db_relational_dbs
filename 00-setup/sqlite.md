# SQLite setup

SQLite is a library, not a server. The whole database is a single file.

| Feature | SQLite | MySQL / PostgreSQL / Oracle |
|---|---|---|
| Server process | No | Yes |
| Users and passwords | No | Yes |
| Database is | A file | Managed by the server |
| Setup | `apt install` and go | Heavier |
| Concurrent writers | One at a time | Many |
| Typical use | Mobile apps, desktop apps, tests, prototyping | Multi-user applications |

Because there is no server, there are no users to create and `GRANT`/`REVOKE` don't exist.

## Install

```bash
sudo apt update
sudo apt install sqlite3
sqlite3 --version
```

## Create a database

```bash
sqlite3 sqltutorial.db      # creates the file if it does not exist
```

The prompt changes to `sqlite>`.

## Load the sample database

```bash
sqlite3 sqltutorial.db "PRAGMA foreign_keys = ON;" \
  ".read sample-db/schema.sql" ".read sample-db/seed.sql"
```

SQLite reports an error on the PostgreSQL-only `SET` on line 1 and on `CASCADE` in the `DROP` lines; the tables are still created. On a fresh file you can skip `schema.sql`'s `DROP`s entirely.

## Example table with an auto-increment key

```sql
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone   TEXT,
    email   TEXT
);

INSERT INTO users (phone, email) VALUES ('123456', 'test@gmail.com');
```

`INTEGER PRIMARY KEY` alone already auto-assigns ids. `AUTOINCREMENT` additionally guarantees ids are never reused after deletes.

## sqlite3 cheat sheet

| Command | Does |
|---|---|
| `.tables` | List tables |
| `.schema t` | Show the `CREATE` statement |
| `.headers on` / `.mode column` | Readable output |
| `.read file.sql` | Run a file |
| `.quit` | Exit |

## Things SQLite lacks

Stored procedures, `GRANT`/`REVOKE`, `RIGHT`/`FULL JOIN` before 3.39, strict types (unless you use `STRICT` tables), and most `ALTER TABLE` operations other than add/rename/drop column.
