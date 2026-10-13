-- 02 · CREATE TABLE in Oracle

-- Without a primary key
CREATE TABLE users_nopk (
    id          NUMBER(10)    NOT NULL,
    name        VARCHAR2(40)  NOT NULL,
    department  VARCHAR2(10)
);

-- With a primary key
CREATE TABLE users (
    id          NUMBER(10)    NOT NULL,
    name        VARCHAR2(40)  NOT NULL,
    department  VARCHAR2(10),
    PRIMARY KEY (id)
);

-- Identity column (Oracle 12c+)
CREATE TABLE users_identity (
    id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  VARCHAR2(40) NOT NULL
);

-- Old style: a sequence supplies the ids
CREATE SEQUENCE users_seq START WITH 1 INCREMENT BY 1;
INSERT INTO users (id, name, department) VALUES (users_seq.NEXTVAL, 'Subbu P', 'IT');

-- List all the tables you own
SELECT table_name FROM user_tables;

-- Describe a table (SQL*Plus / SQL Developer command)
DESC users;

DROP TABLE users_nopk;
DROP TABLE users_identity;
DROP TABLE users;
DROP SEQUENCE users_seq;
