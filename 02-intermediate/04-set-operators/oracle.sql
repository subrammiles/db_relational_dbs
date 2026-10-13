-- 04 · Set operators in Oracle

-- ---------------------------------------------------------------
-- UNION / UNION ALL
-- Combines the result sets of two or more SELECT statements.
--   * every SELECT must have the same number of columns
--   * the columns must have similar data types
--   * the columns must be in the same order
-- ---------------------------------------------------------------
CREATE TABLE travel_expense (
    name  VARCHAR2(15)  NOT NULL,
    day1  NUMBER(5)     NOT NULL,
    day2  NUMBER(5)     NOT NULL,
    day3  NUMBER(5)     NOT NULL,
    PRIMARY KEY (name)
);

INSERT ALL
    INTO travel_expense (name, day1, day2, day3) VALUES ('Trump',    100,   0,  10)
    INTO travel_expense (name, day1, day2, day3) VALUES ('Shiva',     45, 200, 500)
    INTO travel_expense (name, day1, day2, day3) VALUES ('ChanChi',    0,   0,  52)
    INTO travel_expense (name, day1, day2, day3) VALUES ('Samantha', 100, 100, 100)
SELECT * FROM dual;

-- UNION ALL keeps duplicates: 12 rows
--   100, 45, 0, 100,  0, 200, 0, 100,  10, 500, 52, 100
SELECT day1 FROM travel_expense
UNION ALL
SELECT day2 FROM travel_expense
UNION ALL
SELECT day3 FROM travel_expense;

-- UNION removes duplicates: 0, 10, 45, 52, 100, 200, 500
SELECT day1 FROM travel_expense
UNION
SELECT day2 FROM travel_expense
UNION
SELECT day3 FROM travel_expense;

-- ---------------------------------------------------------------
-- INTERSECT: rows common to every SELECT
-- Was any vegetable sold in all three stores (on some day)?
-- ---------------------------------------------------------------
CREATE TABLE sold_items (
    dates   VARCHAR2(15)  NOT NULL,
    store1  VARCHAR2(20)  NOT NULL,
    store2  VARCHAR2(20)  NOT NULL,
    store3  VARCHAR2(20)  NOT NULL,
    PRIMARY KEY (dates)
);

INSERT ALL
    INTO sold_items (dates, store1, store2, store3) VALUES ('day1', 'Carrots',   'Onions',   'Beet')
    INTO sold_items (dates, store1, store2, store3) VALUES ('day2', 'Asparagus', 'Carrots',  'Beet')
    INTO sold_items (dates, store1, store2, store3) VALUES ('day3', 'Broccoli',  'Broccoli', 'Onions')
    INTO sold_items (dates, store1, store2, store3) VALUES ('day4', 'Onions',    'Carrots',  'Onions')
SELECT * FROM dual;

SELECT store1 FROM sold_items
INTERSECT
SELECT store2 FROM sold_items
INTERSECT
SELECT store3 FROM sold_items;
-- Result: Onions (the only item that appears in all three stores' lists)

-- ---------------------------------------------------------------
-- MINUS (Oracle's name for EXCEPT): in the first query, not in the second
-- ---------------------------------------------------------------
-- Items store1 sold that store2 never sold: Asparagus
SELECT store1 FROM sold_items
MINUS
SELECT store2 FROM sold_items;

DROP TABLE travel_expense;
DROP TABLE sold_items;
