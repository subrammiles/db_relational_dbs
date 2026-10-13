-- 02 · CREATE TABLE in SQLite
-- Run with:  sqlite3 test.db ".read 01-basics/02-create-table-and-data-types/sqlite.sql"

CREATE TABLE IF NOT EXISTS users (
    user_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    phone    TEXT,
    email    TEXT
);

INSERT INTO users (phone, email) VALUES ('123456', 'test@gmail.com');

SELECT * FROM users;

-- SQLite uses "type affinity": the number 987654 is silently converted to TEXT for this column
INSERT INTO users (phone, email) VALUES (987654, 'test2@gmail.com');
SELECT phone, typeof(phone) FROM users;

-- STRICT tables (SQLite 3.37+) enforce types like other databases
CREATE TABLE IF NOT EXISTS strict_users (
    user_id  INTEGER PRIMARY KEY,
    age      INTEGER
) STRICT;
-- INSERT INTO strict_users (age) VALUES ('abc');   -- ERROR: cannot store TEXT value in INTEGER column

DROP TABLE strict_users;
DROP TABLE users;
