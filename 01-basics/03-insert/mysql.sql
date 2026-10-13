-- 03 · INSERT in MySQL

CREATE DATABASE IF NOT EXISTS testDB;
USE testDB;

CREATE TABLE users (
    user_id  INT          NOT NULL AUTO_INCREMENT,
    phone    VARCHAR(15)  NOT NULL,
    email    VARCHAR(60)  NOT NULL,
    PRIMARY KEY (user_id)
);

-- One row
INSERT INTO users (phone, email)
VALUES ('123456', 'test@gmail.com');

-- The id MySQL just generated for this connection
SELECT LAST_INSERT_ID();

-- Many rows
INSERT INTO users (phone, email)
VALUES
    ('123456', 'test1@gmail.com'),
    ('987654', 'test2@gmail.com'),
    ('555666', 'test3@gmail.com'),
    ('777888', 'test4@gmail.com');

-- Skip rows that would violate a unique/primary key instead of failing
INSERT IGNORE INTO users (user_id, phone, email) VALUES (1, '000', 'dup@gmail.com');

SELECT * FROM users;

DROP TABLE users;
