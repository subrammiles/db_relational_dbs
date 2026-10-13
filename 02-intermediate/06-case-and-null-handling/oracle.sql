-- 06 · DECODE, NVL, NVL2 and CASE in Oracle

-- DECODE(expr, search1, result1, search2, result2, ..., default)
-- is Oracle's compact form of a simple CASE.
-- returns 'Not Equal'
SELECT DECODE(1, 2, 'Equal', 'Not Equal') AS result FROM dual;
-- equivalent to:
--   IF 1 = 2 THEN 'Equal' ELSE 'Not Equal' END IF;
SELECT CASE WHEN 1 = 2 THEN 'Equal' ELSE 'Not Equal' END AS result FROM dual;

CREATE TABLE orders_demo (
    order_id  NUMBER PRIMARY KEY,
    status    VARCHAR2(20),
    discount  NUMBER
);

INSERT ALL
    INTO orders_demo VALUES (1, 'D', 10)
    INTO orders_demo VALUES (2, 'S', NULL)
    INTO orders_demo VALUES (3, 'C', 0)
    INTO orders_demo VALUES (4, NULL, NULL)
SELECT * FROM dual;

-- DECODE with several pairs and a default
SELECT order_id,
       DECODE(status, 'D', 'Delivered', 'S', 'Shipped', 'C', 'Cancelled', 'Unknown') AS status_name
FROM orders_demo;

-- DECODE treats NULL = NULL as a match (CASE does not)
SELECT order_id,
       DECODE(status, NULL, 'missing', 'present')                    AS with_decode,
       CASE status WHEN NULL THEN 'missing' ELSE 'present' END       AS with_simple_case,  -- always 'present'
       CASE WHEN status IS NULL THEN 'missing' ELSE 'present' END    AS with_searched_case
FROM orders_demo;

-- NVL(a, b): b if a is NULL
SELECT order_id, NVL(discount, 0) AS discount FROM orders_demo;

-- NVL2(a, x, y): x if a is NOT NULL, y if it is NULL
SELECT order_id, NVL2(discount, 'has discount', 'no discount') AS info FROM orders_demo;

-- COALESCE works in Oracle too, and is standard
SELECT order_id, COALESCE(discount, 0) AS discount FROM orders_demo;

-- In Oracle the empty string IS NULL
SELECT CASE WHEN '' IS NULL THEN 'empty string is NULL' ELSE 'not NULL' END AS oracle_quirk FROM dual;

DROP TABLE orders_demo;
