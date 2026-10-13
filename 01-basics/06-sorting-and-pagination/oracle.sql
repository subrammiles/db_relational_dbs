-- 06 · ORDER BY and pagination in Oracle
--
-- ORDER BY sorts the rows of a SELECT:
--   ORDER BY <expression> [ASC | DESC] [NULLS FIRST | NULLS LAST]

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

-- Ascending (default)
SELECT * FROM users ORDER BY country;

-- Descending
SELECT * FROM users ORDER BY country DESC;

-- Two keys
SELECT * FROM users ORDER BY country, name;

-- Pagination, Oracle 12c+: skip 1 row, then take 5
SELECT * FROM users
ORDER BY id
OFFSET 1 ROWS FETCH NEXT 5 ROWS ONLY;

-- Top N, Oracle 12c+
SELECT * FROM users ORDER BY name FETCH FIRST 3 ROWS ONLY;

-- Top N before 12c: sort in a subquery FIRST, then apply ROWNUM
SELECT * FROM (
    SELECT * FROM users ORDER BY name
) WHERE ROWNUM <= 3;

-- Wrong: ROWNUM is assigned before ORDER BY, so these are 3 arbitrary rows, then sorted
SELECT * FROM users WHERE ROWNUM <= 3 ORDER BY name;

-- Rows 4-6 before 12c
SELECT * FROM (
    SELECT u.*, ROWNUM AS rn FROM (SELECT * FROM users ORDER BY id) u
    WHERE ROWNUM <= 6
) WHERE rn > 3;

DROP TABLE users;
