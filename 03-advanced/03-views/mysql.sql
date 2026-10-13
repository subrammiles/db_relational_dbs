-- 03 · Views in MySQL

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id  INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(50),
    city         VARCHAR(50)
);

CREATE TABLE orders (
    order_id     INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT,
    product      VARCHAR(50),
    amount       INT
);

INSERT INTO customers (name, city) VALUES
    ('Alice', 'Bangalore'),
    ('Bob',   'Delhi');

INSERT INTO orders (customer_id, product, amount) VALUES
    (1, 'Laptop', 70000),
    (1, 'Mouse',    500),
    (2, 'Phone',  30000);

-- Simple view
CREATE VIEW customer_orders AS
SELECT c.name, c.city, o.product, o.amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;

SELECT * FROM customer_orders;

-- Change ("update") the view definition
CREATE OR REPLACE VIEW customer_orders AS
SELECT c.name, o.product
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id;

SELECT * FROM customer_orders;

-- Inspect
SHOW FULL TABLES WHERE Table_type = 'VIEW';
SHOW CREATE VIEW customer_orders;

-- Updatable single-table view with CHECK OPTION
CREATE VIEW big_orders AS
SELECT order_id, customer_id, product, amount FROM orders WHERE amount >= 10000
WITH CHECK OPTION;

UPDATE big_orders SET amount = 75000 WHERE order_id = 1;   -- ok
-- UPDATE big_orders SET amount = 100 WHERE order_id = 1;  -- ERROR 1369: CHECK OPTION failed

-- MySQL has no materialized views: emulate with a summary table refreshed on a schedule
CREATE TABLE customer_totals AS
SELECT customer_id, SUM(amount) AS total FROM orders GROUP BY customer_id;

DROP TABLE customer_totals;
DROP VIEW big_orders;
DROP VIEW customer_orders;
DROP TABLE orders;
DROP TABLE customers;
