-- 15 · JSON in SQL (PostgreSQL JSONB)

-- Variable product attributes stored as JSONB next to the regular columns
ALTER TABLE products ADD COLUMN attrs JSONB NOT NULL DEFAULT '{}';

UPDATE products SET attrs = '{"brand": "Acme", "ram_gb": 16, "cpu": "M3", "tags": ["laptop", "portable"], "dims": {"width": 31, "depth": 22}}' WHERE product_id = 1;
UPDATE products SET attrs = '{"brand": "Clicky", "wireless": true, "dpi": 1600, "tags": ["wireless", "accessory"]}' WHERE product_id = 2;
UPDATE products SET attrs = '{"brand": "Clicky", "switches": "brown", "wireless": false, "tags": ["accessory"]}' WHERE product_id = 3;
UPDATE products SET attrs = '{"brand": "ViewMax", "size_in": 27, "panel": "IPS", "tags": ["display"]}' WHERE product_id = 4;
UPDATE products SET attrs = '{"brand": "SitWell", "material": "mesh", "warranty_years": 5, "tags": ["ergonomic"]}' WHERE product_id = 5;
UPDATE products SET attrs = '{"brand": "SitWell", "motorised": true, "warranty_years": 3, "dims": {"width": 140, "depth": 70}}' WHERE product_id = 6;

-- ---------------------------------------------------------------
-- 1. Reading values
-- ---------------------------------------------------------------
SELECT product_name,
       attrs -> 'brand'               AS brand_json,      -- "Acme" (JSON, with quotes)
       attrs ->> 'brand'              AS brand_text,      -- Acme   (text)
       attrs -> 'dims' ->> 'width'    AS width,           -- nested
       attrs #>> '{dims,depth}'       AS depth,           -- nested by path array
       attrs -> 'tags' ->> 0          AS first_tag,       -- array element (0-based)
       jsonb_array_length(attrs -> 'tags') AS tag_count
FROM products
WHERE attrs <> '{}'
ORDER BY product_id;

-- ->> returns text: cast before numeric comparisons
SELECT product_name, (attrs ->> 'ram_gb')::INT AS ram_gb
FROM products
WHERE (attrs ->> 'ram_gb')::INT >= 16;

-- ---------------------------------------------------------------
-- 2. Filtering
-- ---------------------------------------------------------------
SELECT product_name FROM products WHERE attrs ->> 'brand' = 'Clicky';
SELECT product_name FROM products WHERE attrs @> '{"brand": "SitWell"}';        -- containment
SELECT product_name FROM products WHERE attrs @> '{"wireless": true}';
SELECT product_name FROM products WHERE attrs ? 'warranty_years';               -- key exists
SELECT product_name FROM products WHERE attrs -> 'tags' ? 'accessory';         -- array contains
SELECT product_name FROM products WHERE attrs ?| ARRAY['dpi', 'panel'];        -- any of these keys

-- SQL/JSON path (standard): products wider than 100
SELECT product_name FROM products WHERE attrs @? '$.dims.width ? (@ > 100)';

-- ---------------------------------------------------------------
-- 3. JSON → rows
-- ---------------------------------------------------------------
-- One row per tag
SELECT p.product_name, t.tag
FROM products p
CROSS JOIN LATERAL jsonb_array_elements_text(p.attrs -> 'tags') AS t(tag)
ORDER BY t.tag, p.product_name;

-- Tag popularity
SELECT tag, COUNT(*) AS products
FROM products, jsonb_array_elements_text(attrs -> 'tags') AS tag
GROUP BY tag
ORDER BY products DESC, tag;

-- Every key/value pair of one document
SELECT key, value, jsonb_typeof(value) AS type
FROM products, jsonb_each(attrs)
WHERE product_id = 1;

-- JSON → typed columns
SELECT p.product_name, r.*
FROM products p,
     jsonb_to_record(p.attrs) AS r(brand TEXT, warranty_years INT, motorised BOOLEAN)
WHERE p.category = 'Furniture' AND p.attrs <> '{}';

-- ---------------------------------------------------------------
-- 4. Rows → JSON (e.g. one API response per order)
-- ---------------------------------------------------------------
SELECT jsonb_build_object(
           'order_id', o.order_id,
           'date',     o.order_date,
           'customer', c.name,
           'items',    jsonb_agg(jsonb_build_object(
                           'product',  p.product_name,
                           'qty',      oi.quantity,
                           'price',    oi.unit_price) ORDER BY p.product_name),
           'total',    SUM(oi.quantity * oi.unit_price)
       ) AS order_json
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
JOIN products p     ON p.product_id  = oi.product_id
WHERE o.order_id IN (1, 4)
GROUP BY o.order_id, o.order_date, c.name
ORDER BY o.order_id;

-- A whole row as JSON
SELECT to_jsonb(d) FROM departments d WHERE dept_id = 1;

-- ---------------------------------------------------------------
-- 5. Modifying JSON
-- ---------------------------------------------------------------
UPDATE products SET attrs = jsonb_set(attrs, '{ram_gb}', '32') WHERE product_id = 1;            -- set a value
UPDATE products SET attrs = attrs || '{"color": "black"}' WHERE product_id = 2;                 -- add / merge keys
UPDATE products SET attrs = attrs - 'switches' WHERE product_id = 3;                            -- remove a key
UPDATE products SET attrs = jsonb_set(attrs, '{tags}', (attrs -> 'tags') || '"sale"') WHERE product_id = 4;  -- append to array
SELECT product_id, attrs FROM products WHERE product_id IN (1, 2, 3, 4) ORDER BY product_id;

-- ---------------------------------------------------------------
-- 6. Indexing
-- ---------------------------------------------------------------
CREATE INDEX products_attrs_gin   ON products USING GIN (attrs);               -- @>, ?, ?| ?&
CREATE INDEX products_attrs_brand ON products ((attrs ->> 'brand'));           -- equality on one field

-- (With 10 rows the planner prefers a Seq Scan; on a large table these use the indexes.)
SET enable_seqscan = off;
EXPLAIN SELECT product_name FROM products WHERE attrs @> '{"brand": "SitWell"}';
EXPLAIN SELECT product_name FROM products WHERE attrs ->> 'brand' = 'SitWell';
RESET enable_seqscan;

-- Validate structure with a CHECK constraint
ALTER TABLE products ADD CONSTRAINT attrs_is_object CHECK (jsonb_typeof(attrs) = 'object');
ALTER TABLE products ADD CONSTRAINT attrs_tags_array
    CHECK (NOT attrs ? 'tags' OR jsonb_typeof(attrs -> 'tags') = 'array');

-- JSON vs JSONB: JSON keeps the text exactly, JSONB normalises it
SELECT '{"b": 1, "a": 2, "a": 3}'::JSON  AS json_text,       -- as typed
       '{"b": 1, "a": 2, "a": 3}'::JSONB AS jsonb_value;     -- {"a": 3, "b": 1}

ALTER TABLE products DROP COLUMN attrs;
