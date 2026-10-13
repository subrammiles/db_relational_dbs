-- 03 · INSERT in Oracle

CREATE TABLE users (
    id          NUMBER(10)    NOT NULL,
    name        VARCHAR2(40)  NOT NULL,
    department  VARCHAR2(10),
    PRIMARY KEY (id)
);

-- One row
INSERT INTO users (id, name, department) VALUES (1, 'Subbu P', 'IT');

-- Several rows: INSERT ALL ... SELECT * FROM dual
-- (dual is a one-row dummy table; the SELECT drives the insert exactly once)
INSERT ALL
    INTO users (id, name, department) VALUES (2, 'Samantha', 'HR')
    INTO users (id, name, department) VALUES (3, 'Jackie Chan', 'IT')
    INTO users (id, name, department) VALUES (4, 'Rama Siva', 'Sales')
SELECT * FROM dual;

-- Oracle 23c only: multi-row VALUES like other databases
-- INSERT INTO users (id, name, department) VALUES (5, 'A', 'IT'), (6, 'B', 'HR');

-- Changes are not visible to other sessions until you commit
COMMIT;

SELECT * FROM users;

DROP TABLE users;
