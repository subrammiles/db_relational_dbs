-- 08 · UPDATE and DELETE in Oracle

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

SELECT * FROM employee;

-- Update one row
UPDATE employee SET full_name = 'Krish' WHERE emp_id = 28;

-- Delete one row
DELETE FROM employee WHERE emp_id = 30;

-- Oracle does not auto-commit: other sessions see nothing until COMMIT
COMMIT;

-- Undo uncommitted work
UPDATE employee SET full_name = 'Oops';
ROLLBACK;
SELECT * FROM employee;      -- names unchanged

DROP TABLE employee;
