-- 08 · Exercises with solutions

-- 1. Design a `reviews` table: each customer may review each product at most once,
--    rating must be 1-5, review text optional, created_at defaults to now.
--    Deleting a product should delete its reviews; deleting a customer should be blocked.
DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews (
    customer_id  INT NOT NULL REFERENCES customers (customer_id) ON DELETE RESTRICT,
    product_id   INT NOT NULL REFERENCES products  (product_id)  ON DELETE CASCADE,
    rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    body         TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (customer_id, product_id)
);
CREATE INDEX reviews_product_idx ON reviews (product_id);

INSERT INTO reviews (customer_id, product_id, rating, body) VALUES (1, 1, 5, 'Great laptop');

-- 2. Add a rule to `products` that the product_name must be unique.
ALTER TABLE products ADD CONSTRAINT products_name_uq UNIQUE (product_name);

-- 3. Add a rule to `orders` that order_date can't be before 2020.
ALTER TABLE orders ADD CONSTRAINT orders_date_chk CHECK (order_date >= DATE '2020-01-01');

-- 4. Which foreign keys point at the `customers` table?
SELECT conname, conrelid::regclass AS child_table
FROM pg_constraint
WHERE contype = 'f' AND confrelid = 'customers'::regclass;

DROP TABLE reviews;
