-- 11 · MERGE in Oracle

CREATE TABLE products (
    product_id  NUMBER PRIMARY KEY,
    name        VARCHAR2(50) NOT NULL,
    price       NUMBER(10,2) NOT NULL,
    stock       NUMBER DEFAULT 0 NOT NULL
);

INSERT ALL
    INTO products VALUES (1, 'Mouse',    800,  100)
    INTO products VALUES (2, 'Keyboard', 4500, 20)
    INTO products VALUES (3, 'Lamp',     1800, 0)
SELECT * FROM dual;

CREATE TABLE price_feed (
    product_id    NUMBER,
    name          VARCHAR2(50),
    price         NUMBER(10,2),
    discontinued  CHAR(1)
);

INSERT ALL
    INTO price_feed VALUES (1, 'Mouse',  750,  'N')   -- price change
    INTO price_feed VALUES (3, 'Lamp',   1800, 'Y')   -- discontinued
    INTO price_feed VALUES (4, 'Webcam', 3500, 'N')   -- new
SELECT * FROM dual;

-- Oracle's MERGE: the DELETE clause removes rows that were just UPDATEd and match its condition
MERGE INTO products p
USING price_feed f
ON (p.product_id = f.product_id)
WHEN MATCHED THEN
    UPDATE SET p.price = f.price
    DELETE WHERE f.discontinued = 'Y'
WHEN NOT MATCHED THEN
    INSERT (product_id, name, price, stock)
    VALUES (f.product_id, f.name, f.price, 0)
    WHERE f.discontinued = 'N';

COMMIT;
SELECT * FROM products ORDER BY product_id;   -- 1 updated, 2 untouched, 3 deleted, 4 inserted

-- Single-row upsert: use DUAL as the source
MERGE INTO products p
USING (SELECT 2 AS product_id, 'Keyboard' AS name, 4200 AS price FROM dual) s
ON (p.product_id = s.product_id)
WHEN MATCHED THEN UPDATE SET p.price = s.price
WHEN NOT MATCHED THEN INSERT (product_id, name, price) VALUES (s.product_id, s.name, s.price);

DROP TABLE price_feed;
DROP TABLE products;
