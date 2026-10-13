-- 09 · Exercises with solutions (run on a copy of customers)

DROP TABLE IF EXISTS cust;
CREATE TABLE cust AS SELECT * FROM customers;

-- 1. Add a column `phone` (up to 20 characters).
ALTER TABLE cust ADD COLUMN phone VARCHAR(20);

-- 2. Add a column `loyalty_points` that can't be NULL and starts at 0.
ALTER TABLE cust ADD COLUMN loyalty_points INT NOT NULL DEFAULT 0;

-- 3. Rename `signup_date` to `joined_on`.
ALTER TABLE cust RENAME COLUMN signup_date TO joined_on;

-- 4. Make customer_id the primary key.
ALTER TABLE cust ADD PRIMARY KEY (customer_id);

-- 5. Remove the `city` column.
ALTER TABLE cust DROP COLUMN city;

-- 6. Empty the table, then drop it.
TRUNCATE TABLE cust;
DROP TABLE cust;
