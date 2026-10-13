-- 02 · CREATE TABLE in MySQL

CREATE DATABASE IF NOT EXISTS mydatabase;
USE mydatabase;

CREATE TABLE users (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;          -- InnoDB is the default; it supports transactions and foreign keys

SHOW TABLES;
DESCRIBE users;
SHOW CREATE TABLE users;

-- Copy structure only (keeps indexes, unlike CREATE TABLE ... AS SELECT)
CREATE TABLE users_copy LIKE users;

DROP TABLE users_copy;
DROP TABLE users;
