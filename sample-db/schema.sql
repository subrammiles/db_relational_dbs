SET client_min_messages = warning;  -- hide "table does not exist, skipping" notices

-- =====================================================================
-- Sample database used by every lesson in this tutorial.
-- Dialect: PostgreSQL (see README.md for MySQL / SQLite / Oracle notes)
--
--   psql -d sqltutorial -f sample-db/schema.sql
--   psql -d sqltutorial -f sample-db/seed.sql
--
-- Re-running this file drops and recreates everything.
-- =====================================================================

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders      CASCADE;
DROP TABLE IF EXISTS products    CASCADE;
DROP TABLE IF EXISTS customers   CASCADE;
DROP TABLE IF EXISTS employees   CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS accounts    CASCADE;

-- ---------------------------------------------------------------------
-- HR side: departments and employees (employees.manager_id -> self)
-- ---------------------------------------------------------------------
CREATE TABLE departments (
    dept_id    INT          PRIMARY KEY,
    dept_name  VARCHAR(50)  NOT NULL UNIQUE,
    location   VARCHAR(50)
);

CREATE TABLE employees (
    emp_id      INT            PRIMARY KEY,
    first_name  VARCHAR(50)    NOT NULL,
    last_name   VARCHAR(50)    NOT NULL,
    email       VARCHAR(100)   UNIQUE,
    dept_id     INT            REFERENCES departments(dept_id),
    manager_id  INT            REFERENCES employees(emp_id),
    job_title   VARCHAR(50)    NOT NULL,
    salary      NUMERIC(10,2)  NOT NULL CHECK (salary > 0),
    hire_date   DATE           NOT NULL
);

-- ---------------------------------------------------------------------
-- Shop side: customers, products, orders, order_items
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id  INT           PRIMARY KEY,
    name         VARCHAR(100)  NOT NULL,
    email        VARCHAR(100)  UNIQUE,
    city         VARCHAR(50),
    country      VARCHAR(50),
    signup_date  DATE          NOT NULL
);

CREATE TABLE products (
    product_id    INT            PRIMARY KEY,
    product_name  VARCHAR(100)   NOT NULL,
    category      VARCHAR(50)    NOT NULL,
    price         NUMERIC(10,2)  NOT NULL CHECK (price >= 0),
    stock         INT            NOT NULL DEFAULT 0 CHECK (stock >= 0)
);

CREATE TABLE orders (
    order_id     INT          PRIMARY KEY,
    customer_id  INT          NOT NULL REFERENCES customers(customer_id),
    order_date   DATE         NOT NULL,
    status       VARCHAR(20)  NOT NULL
                 CHECK (status IN ('pending', 'shipped', 'delivered', 'cancelled'))
);

-- Composite primary key: one row per (order, product)
CREATE TABLE order_items (
    order_id    INT            NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id  INT            NOT NULL REFERENCES products(product_id),
    quantity    INT            NOT NULL CHECK (quantity > 0),
    unit_price  NUMERIC(10,2)  NOT NULL,   -- price actually charged (may differ from list price)
    PRIMARY KEY (order_id, product_id)
);

-- ---------------------------------------------------------------------
-- Bank accounts: used by the transactions / ACID lesson
-- ---------------------------------------------------------------------
CREATE TABLE accounts (
    account_id  INT            PRIMARY KEY,
    owner_name  VARCHAR(50)    NOT NULL,
    balance     NUMERIC(12,2)  NOT NULL CHECK (balance >= 0)
);
