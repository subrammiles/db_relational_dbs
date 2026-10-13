-- 03 · Joins in MySQL
--
-- Most used joins in real projects:
--   1. INNER JOIN  (most queries)
--   2. LEFT JOIN   (very common)
--   3. RIGHT JOIN  (rare: swap the tables and use LEFT JOIN)
--   4. CROSS JOIN  (rare)
--
-- Two tables: customers and orders. A customer can have many orders.

CREATE DATABASE IF NOT EXISTS joinDB;
USE joinDB;

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
    ('Alice',   'Bangalore'),
    ('Bob',     'Delhi'),
    ('Charlie', 'Mumbai'),
    ('David',   'Chennai');      -- no orders

INSERT INTO orders (customer_id, product, amount) VALUES
    (1, 'Laptop', 70000),
    (1, 'Mouse',    500),
    (2, 'Phone',  30000),
    (3, 'Tablet', 20000),
    (9, 'Watch',   5000);        -- customer 9 doesn't exist (no foreign key here)

-- INNER JOIN: only matching rows in both tables (4 rows; no David, no Watch)
SELECT customers.name, orders.product, orders.amount
FROM customers
INNER JOIN orders ON customers.customer_id = orders.customer_id;

-- LEFT JOIN: all customers + their orders; David has NULL product
SELECT customers.name, orders.product
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id;

-- RIGHT JOIN: all orders + their customer; Watch has NULL name
SELECT customers.name, orders.product
FROM customers
RIGHT JOIN orders ON customers.customer_id = orders.customer_id;

-- FULL JOIN is not supported in MySQL. Emulate it with LEFT JOIN UNION RIGHT JOIN.
-- UNION removes the duplicated matched rows; both David and Watch appear.
SELECT customers.name, orders.product
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id
UNION
SELECT customers.name, orders.product
FROM customers
RIGHT JOIN orders ON customers.customer_id = orders.customer_id;

-- If genuine duplicate rows must be kept, use UNION ALL and exclude the matches from the second half:
SELECT c.name, o.product
FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
UNION ALL
SELECT c.name, o.product
FROM customers c RIGHT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

-- CROSS JOIN: every combination. 4 customers x 5 orders = 20 rows.
SELECT customers.name, orders.product
FROM customers
CROSS JOIN orders;

-- JOIN with a WHERE condition: customers who bought a Laptop
SELECT customers.name, orders.product
FROM customers
INNER JOIN orders ON customers.customer_id = orders.customer_id
WHERE orders.product = 'Laptop';

-- Multi-table DELETE with a join: remove orphan orders
DELETE o FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;

DROP TABLE orders;
DROP TABLE customers;
