-- 11 · Upsert in MySQL

DROP TABLE IF EXISTS page_views;
DROP TABLE IF EXISTS products;

CREATE TABLE products (
    product_id  INT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    price       DECIMAL(10,2) NOT NULL,
    stock       INT NOT NULL DEFAULT 0
);

INSERT INTO products VALUES (1, 'Mouse', 800, 100), (2, 'Keyboard', 4500, 20);

-- INSERT ... ON DUPLICATE KEY UPDATE (MySQL 8.0.19+ alias syntax)
INSERT INTO products (product_id, name, price, stock)
VALUES (1, 'Mouse', 750, 50), (3, 'Webcam', 3500, 10) AS new
ON DUPLICATE KEY UPDATE
    price = new.price,
    stock = products.stock + new.stock;

-- Older syntax, deprecated in 8.0.20 but still common:
--   ON DUPLICATE KEY UPDATE price = VALUES(price)

SELECT * FROM products;       -- Mouse 750 / 150, Webcam inserted

-- Counter
CREATE TABLE page_views (page VARCHAR(100) PRIMARY KEY, views INT NOT NULL);
INSERT INTO page_views VALUES ('/home', 1) ON DUPLICATE KEY UPDATE views = views + 1;
INSERT INTO page_views VALUES ('/home', 1) ON DUPLICATE KEY UPDATE views = views + 1;
SELECT * FROM page_views;     -- /home 2

-- INSERT IGNORE: skip rows that would violate a key (also downgrades other errors to warnings!)
INSERT IGNORE INTO products VALUES (2, 'Keyboard v2', 5000, 5);
SHOW WARNINGS;

-- REPLACE INTO: DELETEs the old row, then INSERTs. Unspecified columns get defaults,
-- delete triggers fire, and ON DELETE CASCADE children are deleted.
REPLACE INTO products (product_id, name, price) VALUES (2, 'Keyboard v2', 5000);
SELECT * FROM products WHERE product_id = 2;    -- stock reset to 0!

DROP TABLE page_views;
DROP TABLE products;
