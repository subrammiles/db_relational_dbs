-- 07 · DISTINCT and aliases in Oracle

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

-- Without DISTINCT: includes the duplicate countries
SELECT country FROM users;

-- With DISTINCT: USA, India, China, UK, Germany
SELECT DISTINCT country FROM users;

-- ---------------------------------------------------------------
-- Aliases
-- ---------------------------------------------------------------
CREATE TABLE employee (
    emp_id     NUMBER(15)    NOT NULL,
    full_name  VARCHAR2(20)  NOT NULL,
    PRIMARY KEY (emp_id)
);

CREATE TABLE salary (
    order_id  VARCHAR2(15)  NOT NULL,
    emp_id    NUMBER(15)    NOT NULL,
    amount    NUMBER(20)    NOT NULL,
    PRIMARY KEY (order_id)
);

INSERT ALL
    INTO employee (emp_id, full_name) VALUES (21, 'Samantha')
    INTO employee (emp_id, full_name) VALUES (22, 'Trump')
    INTO employee (emp_id, full_name) VALUES (23, 'Jackie Chan')
    INTO employee (emp_id, full_name) VALUES (24, 'Rama Siva')
SELECT * FROM dual;

INSERT ALL
    INTO salary (order_id, emp_id, amount) VALUES ('TX-23-01', 19, 60000)
    INTO salary (order_id, emp_id, amount) VALUES ('TX-23-02', 20, 358522)
    INTO salary (order_id, emp_id, amount) VALUES ('TX-23-03', 21, 358522)
    INTO salary (order_id, emp_id, amount) VALUES ('TX-23-04', 22, 358522)
    INTO salary (order_id, emp_id, amount) VALUES ('TX-23-05', 23, 45200)
    INTO salary (order_id, emp_id, amount) VALUES ('TX-23-06', 24, 45200)
    INTO salary (order_id, emp_id, amount) VALUES ('TX-23-07', 25, 58255)
SELECT * FROM dual;

-- Column alias: the output column is labelled EMPLOYEE_NO instead of EMP_ID
SELECT emp_id AS employee_no FROM employee;

-- Table aliases: E is employee, S is salary. Oracle does NOT allow "AS" before a table alias.
SELECT e.emp_id, e.full_name, s.amount
FROM employee e
INNER JOIN salary s ON e.emp_id = s.emp_id;

DROP TABLE salary;
DROP TABLE employee;
DROP TABLE users;
