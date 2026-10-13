-- 05 · LIKE in Oracle

CREATE TABLE employee (
    emp_id     NUMBER(15)    NOT NULL,
    full_name  VARCHAR2(20)  NOT NULL,
    PRIMARY KEY (emp_id)
);

INSERT ALL
    INTO employee (emp_id, full_name) VALUES (21, 'Samantha')
    INTO employee (emp_id, full_name) VALUES (22, 'Trump')
    INTO employee (emp_id, full_name) VALUES (23, 'Jackie Chan')
    INTO employee (emp_id, full_name) VALUES (24, 'Rama Siva')
    INTO employee (emp_id, full_name) VALUES (27, 'Ramana')
    INTO employee (emp_id, full_name) VALUES (28, 'Trump')
    INTO employee (emp_id, full_name) VALUES (29, 'Arpitha')
    INTO employee (emp_id, full_name) VALUES (30, 'Fold B')
SELECT * FROM dual;

-- LIKE is case-sensitive in Oracle:
SELECT * FROM employee WHERE full_name LIKE 'sa%';     -- 0 rows
SELECT * FROM employee WHERE full_name LIKE 'Sa%';     -- Samantha

-- Case-insensitive options
SELECT * FROM employee WHERE UPPER(full_name) LIKE 'SA%';
SELECT * FROM employee WHERE REGEXP_LIKE(full_name, '^sa', 'i');

-- Second letter is 'a'
SELECT * FROM employee WHERE full_name LIKE '_a%';

-- IN / BETWEEN
SELECT * FROM employee WHERE emp_id IN (21, 23, 29);
SELECT * FROM employee WHERE emp_id BETWEEN 22 AND 27;

DROP TABLE employee;
