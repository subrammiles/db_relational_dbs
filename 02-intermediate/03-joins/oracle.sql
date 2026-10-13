-- 03 · Joins in Oracle: employee / salary
-- Task: list order id, employee name and salary amount.
-- Both tables contain emp_id. Employees 21-24 have salaries;
-- salary rows for emp_id 19, 20 and 25 have no employee.

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

-- Natural join: matches on emp_id (the only common column)
SELECT * FROM employee NATURAL JOIN salary;

-- Cross join (Cartesian product): 4 x 7 = 28 rows
SELECT * FROM salary CROSS JOIN employee;

-- Inner join: 4 rows
SELECT s.order_id, e.full_name, s.amount
FROM salary s
INNER JOIN employee e ON s.emp_id = e.emp_id;

-- Left outer join: all employees (all 4 have a salary here)
SELECT * FROM employee e LEFT JOIN salary s ON s.emp_id = e.emp_id;

-- Right outer join: all 7 salary rows; 19, 20, 25 have NULL employee columns
SELECT * FROM employee e RIGHT JOIN salary s ON s.emp_id = e.emp_id;

-- Full outer join
SELECT * FROM employee e FULL JOIN salary s ON s.emp_id = e.emp_id;

-- Oracle's legacy outer-join syntax: (+) marks the side that may be missing.
-- Equivalent to the RIGHT JOIN above. Avoid in new code.
SELECT * FROM employee e, salary s WHERE e.emp_id(+) = s.emp_id;

-- ---------------------------------------------------------------
-- NATURAL JOIN vs USING vs ON
-- salary2 has BOTH emp_id and full_name in common with employee.
-- ---------------------------------------------------------------
CREATE TABLE salary2 (
    order_id   VARCHAR2(15)  NOT NULL,
    emp_id     NUMBER(15)    NOT NULL,
    amount     NUMBER(20)    NOT NULL,
    full_name  VARCHAR2(20),
    PRIMARY KEY (order_id)
);

INSERT INTO salary2 (order_id, emp_id, amount, full_name)
SELECT order_id, emp_id, amount, NULL FROM salary;

-- NATURAL JOIN with salary: 4 rows. It compares only emp_id.
SELECT * FROM employee NATURAL JOIN salary;

-- NATURAL JOIN with salary2: 0 rows! It compares emp_id AND full_name,
-- and full_name is NULL in salary2 (NULL never equals anything).
SELECT * FROM employee NATURAL JOIN salary2;

-- Inner join on emp_id only: 4 rows, but emp_id appears twice in SELECT *
SELECT * FROM employee JOIN salary2 ON employee.emp_id = salary2.emp_id;

-- USING (emp_id): 4 rows, and emp_id appears only once
SELECT * FROM employee JOIN salary2 USING (emp_id);

DROP TABLE salary2;
DROP TABLE salary;
DROP TABLE employee;
