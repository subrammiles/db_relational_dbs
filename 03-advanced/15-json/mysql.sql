-- 15 · JSON in MySQL 8

DROP TABLE IF EXISTS json_products;
CREATE TABLE json_products (
    product_id  INT PRIMARY KEY,
    name        VARCHAR(50) NOT NULL,
    attrs       JSON NOT NULL,
    -- generated column extracted from JSON, so it can be indexed
    brand       VARCHAR(50) AS (attrs ->> '$.brand') STORED,
    INDEX idx_brand (brand)
);

INSERT INTO json_products (product_id, name, attrs) VALUES
    (1, 'Laptop', '{"brand": "Acme", "ram_gb": 16, "tags": ["laptop", "portable"], "dims": {"width": 31}}'),
    (2, 'Mouse',  '{"brand": "Clicky", "wireless": true, "tags": ["wireless", "accessory"]}'),
    (3, 'Chair',  '{"brand": "SitWell", "warranty_years": 5, "tags": ["ergonomic"]}');

-- Read: -> returns JSON, ->> returns unquoted text
SELECT name,
       attrs -> '$.brand'          AS brand_json,
       attrs ->> '$.brand'         AS brand_text,
       attrs ->> '$.dims.width'    AS width,
       attrs ->> '$.tags[0]'       AS first_tag,
       JSON_LENGTH(attrs, '$.tags') AS tag_count
FROM json_products;

-- Filter
SELECT name FROM json_products WHERE attrs ->> '$.brand' = 'Clicky';
SELECT name FROM json_products WHERE brand = 'SitWell';                         -- uses idx_brand
SELECT name FROM json_products WHERE JSON_CONTAINS(attrs, '"wireless"', '$.tags');
SELECT name FROM json_products WHERE JSON_CONTAINS_PATH(attrs, 'one', '$.warranty_years');
SELECT name FROM json_products WHERE 'accessory' MEMBER OF (attrs -> '$.tags');  -- 8.0.17+

-- JSON array → rows with JSON_TABLE
SELECT p.name, t.tag
FROM json_products p,
     JSON_TABLE(p.attrs, '$.tags[*]' COLUMNS (tag VARCHAR(30) PATH '$')) AS t;

-- Modify
UPDATE json_products SET attrs = JSON_SET(attrs, '$.ram_gb', 32) WHERE product_id = 1;
UPDATE json_products SET attrs = JSON_INSERT(attrs, '$.color', 'black') WHERE product_id = 2;
UPDATE json_products SET attrs = JSON_REMOVE(attrs, '$.warranty_years') WHERE product_id = 3;
UPDATE json_products SET attrs = JSON_ARRAY_APPEND(attrs, '$.tags', 'sale') WHERE product_id = 1;
SELECT product_id, attrs FROM json_products;

-- Rows → JSON
SELECT JSON_ARRAYAGG(JSON_OBJECT('id', product_id, 'name', name, 'brand', brand)) AS catalog
FROM json_products;

DROP TABLE json_products;
