-- 15 · JSON in Oracle (works on 12.2+ with VARCHAR2/CLOB + IS JSON; 21c adds the JSON type)

CREATE TABLE products (
    product_id  NUMBER PRIMARY KEY,
    name        VARCHAR2(50) NOT NULL,
    attrs       VARCHAR2(4000) CHECK (attrs IS JSON)
);

INSERT INTO products VALUES (1, 'Laptop', '{"brand": "Acme", "ram_gb": 16, "tags": ["laptop", "portable"], "dims": {"width": 31}}');
INSERT INTO products VALUES (2, 'Mouse',  '{"brand": "Clicky", "wireless": true, "tags": ["wireless", "accessory"]}');
INSERT INTO products VALUES (3, 'Chair',  '{"brand": "SitWell", "warranty_years": 5, "tags": ["ergonomic"]}');
COMMIT;

-- JSON_VALUE returns a scalar, JSON_QUERY returns an object/array
SELECT name,
       JSON_VALUE(attrs, '$.brand')                    AS brand,
       JSON_VALUE(attrs, '$.ram_gb' RETURNING NUMBER)  AS ram_gb,
       JSON_VALUE(attrs, '$.dims.width')               AS width,
       JSON_QUERY(attrs, '$.tags')                     AS tags
FROM products;

-- Dot notation (needs a table alias and an IS JSON column)
SELECT p.name, p.attrs.brand FROM products p;

-- Filter
SELECT name FROM products WHERE JSON_VALUE(attrs, '$.brand') = 'Clicky';
SELECT name FROM products WHERE JSON_EXISTS(attrs, '$.warranty_years');
SELECT name FROM products WHERE JSON_EXISTS(attrs, '$.tags[*]?(@ == "accessory")');

-- Array → rows
SELECT p.name, t.tag
FROM products p,
     JSON_TABLE(p.attrs, '$.tags[*]' COLUMNS (tag VARCHAR2(30) PATH '$')) t;

-- Function-based index on one JSON field
CREATE INDEX products_brand_idx ON products (JSON_VALUE(attrs, '$.brand'));

-- Rows → JSON
SELECT JSON_ARRAYAGG(JSON_OBJECT('id' VALUE product_id, 'name' VALUE name)) AS catalog
FROM products;

-- Modify (JSON_MERGEPATCH, 18c+)
UPDATE products SET attrs = JSON_MERGEPATCH(attrs, '{"color": "black"}') WHERE product_id = 2;
SELECT attrs FROM products WHERE product_id = 2;

DROP TABLE products;
