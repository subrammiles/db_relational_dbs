-- 03 · CROSS JOIN (Cartesian product) (PostgreSQL)
--
-- Returns every row of one table combined with every row of the other.
-- If A has 20 rows and B has 30, A CROSS JOIN B has 20 * 30 = 600 rows.

DROP TABLE IF EXISTS meals;
DROP TABLE IF EXISTS drinks;

CREATE TABLE meals  (meal_name  VARCHAR(20));
CREATE TABLE drinks (drink_name VARCHAR(20));

INSERT INTO meals  (meal_name)  VALUES ('Omelette'), ('Fried Egg'), ('Sausage');
INSERT INTO drinks (drink_name) VALUES ('Orange Juice'), ('Tea'), ('Coffee');

-- 3 meals x 3 drinks = 9 breakfast combos
SELECT * FROM meals CROSS JOIN drinks;

-- Same thing with the old comma syntax (easy to do by accident when you forget WHERE)
SELECT * FROM meals, drinks;

-- A real use: build a full grid of (product, month) so months with no sales still show 0
SELECT p.product_name, m.month
FROM products p
CROSS JOIN (VALUES (DATE '2025-01-01'), (DATE '2025-02-01'), (DATE '2025-03-01')) AS m(month)
WHERE p.category = 'Furniture'
ORDER BY p.product_name, m.month;

DROP TABLE meals;
DROP TABLE drinks;
