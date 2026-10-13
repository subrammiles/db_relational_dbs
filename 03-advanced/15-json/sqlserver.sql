-- 15 · JSON in SQL Server 2016+ (stored as NVARCHAR, validated with ISJSON)

DROP TABLE IF EXISTS json_products;
CREATE TABLE json_products (
    product_id  INT PRIMARY KEY,
    name        NVARCHAR(50) NOT NULL,
    attrs       NVARCHAR(MAX) NOT NULL CHECK (ISJSON(attrs) = 1),
    -- computed column on a JSON field, so it can be indexed
    brand AS JSON_VALUE(attrs, '$.brand')
);
CREATE INDEX ix_json_products_brand ON json_products (brand);

INSERT INTO json_products (product_id, name, attrs) VALUES
    (1, N'Laptop', N'{"brand": "Acme", "ram_gb": 16, "tags": ["laptop", "portable"], "dims": {"width": 31}}'),
    (2, N'Mouse',  N'{"brand": "Clicky", "wireless": true, "tags": ["wireless", "accessory"]}'),
    (3, N'Chair',  N'{"brand": "SitWell", "warranty_years": 5, "tags": ["ergonomic"]}');

-- Read
SELECT name,
       JSON_VALUE(attrs, '$.brand')       AS brand,
       JSON_VALUE(attrs, '$.dims.width')  AS width,
       JSON_VALUE(attrs, '$.tags[0]')     AS first_tag,
       JSON_QUERY(attrs, '$.tags')        AS tags
FROM json_products;

-- Filter
SELECT name FROM json_products WHERE brand = 'SitWell';
SELECT name FROM json_products WHERE JSON_VALUE(attrs, '$.warranty_years') IS NOT NULL;

-- Array → rows with OPENJSON + CROSS APPLY
SELECT p.name, t.value AS tag
FROM json_products p
CROSS APPLY OPENJSON(p.attrs, '$.tags') AS t;

-- JSON → typed columns
SELECT p.product_id, j.*
FROM json_products p
CROSS APPLY OPENJSON(p.attrs) WITH (brand NVARCHAR(50) '$.brand', ram_gb INT '$.ram_gb', wireless BIT '$.wireless') AS j;

-- Modify
UPDATE json_products SET attrs = JSON_MODIFY(attrs, '$.ram_gb', 32) WHERE product_id = 1;
UPDATE json_products SET attrs = JSON_MODIFY(attrs, 'append $.tags', 'sale') WHERE product_id = 1;
UPDATE json_products SET attrs = JSON_MODIFY(attrs, '$.warranty_years', NULL) WHERE product_id = 3;   -- NULL removes the key
SELECT product_id, attrs FROM json_products;

-- Rows → JSON
SELECT product_id AS id, name, brand FROM json_products FOR JSON PATH;

DROP TABLE json_products;
