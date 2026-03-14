SQLite is very lightweight compared to MySQL/PostgreSQL.
It does not run a server, so:

❌ No database service

❌ No users/passwords

✔ Database is just a single file

So you do not create users like in MySQL or PostgreSQL.

| Feature  | SQLite      | MySQL/Postgres |
| -------- | ----------- | -------------- |
| Server   | ❌           | ✔              |
| Users    | ❌           | ✔              |
| Database | file        | server         |
| Setup    | very simple | heavier        |
