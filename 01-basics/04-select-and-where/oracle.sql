-- 04 · SELECT in Oracle
-- In a SELECT expression the FROM clause is mandatory. FROM names the table we're reading.

CREATE TABLE users (
    id       NUMBER(10)    NOT NULL,
    name     VARCHAR2(40)  NOT NULL,
    country  VARCHAR2(10),
    PRIMARY KEY (id)
);

INSERT ALL
    INTO users (id, name, country) VALUES (1,  'James G',  'USA')
    INTO users (id, name, country) VALUES (2,  'Jack',     'USA')
    INTO users (id, name, country) VALUES (3,  'Samantha', 'USA')
    INTO users (id, name, country) VALUES (4,  'Rose',     'USA')
    INTO users (id, name, country) VALUES (5,  'Ram',      'India')
    INTO users (id, name, country) VALUES (6,  'Sita',     'India')
    INTO users (id, name, country) VALUES (7,  'Chan Che', 'China')
    INTO users (id, name, country) VALUES (8,  'Shalok',   'UK')
    INTO users (id, name, country) VALUES (9,  'Kinergan', 'Germany')
    INTO users (id, name, country) VALUES (10, 'GutanTag', 'Germany')
SELECT * FROM dual;

SELECT * FROM users;
SELECT name, country FROM users WHERE country = 'India';

-- Expressions with no table still need FROM: use the one-row table DUAL
SELECT 2 + 3 AS answer, SYSDATE AS now FROM dual;

-- Database name (requires DBA privileges)
-- SELECT name FROM v$database;
-- DESCRIBE v$database;

DROP TABLE users;
