-- 08 · UPDATE and DELETE in MySQL
--
-- Basic syntax:
--   UPDATE table_name SET column1 = value1, column2 = value2 WHERE condition;
--   DELETE FROM table_name WHERE condition;

CREATE DATABASE IF NOT EXISTS testDB;
USE testDB;

CREATE TABLE users (
    user_id  INT          NOT NULL AUTO_INCREMENT,
    phone    VARCHAR(15)  NOT NULL,
    email    VARCHAR(60)  NOT NULL,
    PRIMARY KEY (user_id)
);

CREATE TABLE banned_phones (phone VARCHAR(15) PRIMARY KEY);

INSERT INTO users (phone, email) VALUES
    ('123456', 'test@gmail.com'),
    ('987654', 'test2@gmail.com'),
    ('555666', 'test3@gmail.com');

INSERT INTO banned_phones VALUES ('555666');

UPDATE users
SET email = 'updated@gmail.com'
WHERE phone = '123456';

-- MySQL multi-table UPDATE uses JOIN
UPDATE users u
JOIN banned_phones b ON b.phone = u.phone
SET u.email = CONCAT('banned+', u.email);

-- MySQL multi-table DELETE names the table to delete from before FROM
DELETE u
FROM users u
JOIN banned_phones b ON b.phone = u.phone;

SELECT * FROM users;

-- Safe-update mode (on by default in MySQL Workbench) rejects UPDATE/DELETE
-- whose WHERE does not use a key column:
SET SQL_SAFE_UPDATES = 1;
-- DELETE FROM users WHERE email LIKE '%gmail%';   -- ERROR 1175: You are using safe update mode ...
SET SQL_SAFE_UPDATES = 0;

DROP TABLE users;
DROP TABLE banned_phones;
