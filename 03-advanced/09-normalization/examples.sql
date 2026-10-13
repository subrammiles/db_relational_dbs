-- 09 · Normalizing a flat table (PostgreSQL)
-- Uses its own n_* tables so the sample database isn't touched.

DROP TABLE IF EXISTS n_order_items, n_orders, n_customers, n_products, flat_orders;

-- ---------------------------------------------------------------
-- The un-normalized starting point
-- ---------------------------------------------------------------
CREATE TABLE flat_orders (
    order_id       INT,
    order_date     DATE,
    customer_name  VARCHAR(50),
    customer_city  VARCHAR(50),
    product        VARCHAR(50),
    category       VARCHAR(50),
    price          NUMERIC(10,2),
    qty            INT
);

INSERT INTO flat_orders VALUES
    (1, '2025-01-10', 'Aarav', 'Mumbai',    'Laptop',   'Electronics', 85000,  1),
    (1, '2025-01-10', 'Aarav', 'Mumbai',    'Mouse',    'Electronics',   800,  1),
    (2, '2025-02-14', 'Aarav', 'Mumbai',    'Notebook', 'Stationery',    250, 10),
    (3, '2025-02-20', 'Isha',  'Ahmedabad', 'Chair',    'Furniture',   12000,  2);

-- Update anomaly: changing Aarav's city must touch every one of his rows
UPDATE flat_orders SET customer_city = 'Pune' WHERE customer_name = 'Aarav' AND order_id = 1;
SELECT DISTINCT customer_name, customer_city FROM flat_orders;    -- Aarav now has TWO cities!
UPDATE flat_orders SET customer_city = 'Mumbai' WHERE customer_name = 'Aarav';

-- Find the redundancy: values that repeat for the same determinant
SELECT customer_name, COUNT(*) AS rows_storing_the_same_city FROM flat_orders GROUP BY customer_name;
SELECT product, COUNT(DISTINCT price) AS prices FROM flat_orders GROUP BY product;

-- ---------------------------------------------------------------
-- 3NF design
-- ---------------------------------------------------------------
CREATE TABLE n_customers (
    customer_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(50) NOT NULL UNIQUE,
    city         VARCHAR(50)
);

CREATE TABLE n_products (
    product_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(50)   NOT NULL UNIQUE,
    category    VARCHAR(50)   NOT NULL,
    price       NUMERIC(10,2) NOT NULL
);

CREATE TABLE n_orders (
    order_id     INT  PRIMARY KEY,
    order_date   DATE NOT NULL,
    customer_id  INT  NOT NULL REFERENCES n_customers (customer_id)
);

CREATE TABLE n_order_items (
    order_id    INT NOT NULL REFERENCES n_orders (order_id),
    product_id  INT NOT NULL REFERENCES n_products (product_id),
    qty         INT NOT NULL CHECK (qty > 0),
    unit_price  NUMERIC(10,2) NOT NULL,          -- price at time of sale: a historical fact
    PRIMARY KEY (order_id, product_id)
);

-- Migrate the data with INSERT ... SELECT DISTINCT
INSERT INTO n_customers (name, city)
SELECT DISTINCT customer_name, customer_city FROM flat_orders;

INSERT INTO n_products (name, category, price)
SELECT DISTINCT product, category, price FROM flat_orders;

INSERT INTO n_orders (order_id, order_date, customer_id)
SELECT DISTINCT f.order_id, f.order_date, c.customer_id
FROM flat_orders f JOIN n_customers c ON c.name = f.customer_name;

INSERT INTO n_order_items (order_id, product_id, qty, unit_price)
SELECT f.order_id, p.product_id, f.qty, f.price
FROM flat_orders f JOIN n_products p ON p.name = f.product;

-- The anomalies are gone:
-- * update: Aarav's city lives in exactly one row
UPDATE n_customers SET city = 'Pune' WHERE name = 'Aarav';
-- * insert: a product can exist before anyone orders it
INSERT INTO n_products (name, category, price) VALUES ('Desk Lamp', 'Furniture', 1800);
-- * delete: removing order 3 keeps Isha and the Chair
DELETE FROM n_order_items WHERE order_id = 3;
DELETE FROM n_orders WHERE order_id = 3;
SELECT name, city FROM n_customers;
SELECT name, price FROM n_products;

-- A join view reproduces the original flat shape whenever you need it
CREATE VIEW n_flat AS
SELECT o.order_id, o.order_date, c.name AS customer_name, c.city AS customer_city,
       p.name AS product, p.category, oi.unit_price AS price, oi.qty
FROM n_orders o
JOIN n_customers c    ON c.customer_id = o.customer_id
JOIN n_order_items oi ON oi.order_id   = o.order_id
JOIN n_products p     ON p.product_id  = oi.product_id;

SELECT * FROM n_flat ORDER BY order_id, product;

-- ---------------------------------------------------------------
-- 1NF violation and fix: a comma-separated list in one column
-- ---------------------------------------------------------------
CREATE TEMP TABLE contacts_bad (person VARCHAR(20), phones VARCHAR(100));
INSERT INTO contacts_bad VALUES ('Ana', '111, 222'), ('Ben', '333');

-- Querying a list column is awkward and can't use an index:
SELECT person FROM contacts_bad WHERE phones LIKE '%222%';

-- 1NF: one row per value
CREATE TEMP TABLE contacts (person VARCHAR(20), phone VARCHAR(20), PRIMARY KEY (person, phone));
INSERT INTO contacts
SELECT person, TRIM(unnest(string_to_array(phones, ','))) FROM contacts_bad;
SELECT * FROM contacts;

DROP VIEW n_flat;
DROP TABLE n_order_items, n_orders, n_customers, n_products, flat_orders;
