-- 04 · Set operators (PostgreSQL)

-- All cities we have a presence in: customer cities + office locations (each once)
SELECT city AS place FROM customers
UNION
SELECT location FROM departments
ORDER BY place;

-- UNION ALL keeps duplicates (Bangalore, Mumbai appear more than once)
SELECT city AS place FROM customers
UNION ALL
SELECT location FROM departments
ORDER BY place;

-- INTERSECT: cities that have both customers and an office
SELECT city FROM customers
INTERSECT
SELECT location FROM departments;

-- EXCEPT: customer cities with no office
SELECT city FROM customers
EXCEPT
SELECT location FROM departments
ORDER BY city;

-- EXCEPT for "never ordered": customer ids minus those in orders
SELECT customer_id FROM customers
EXCEPT
SELECT customer_id FROM orders;

-- Products sold in both 2025-Q1 and 2025-Q4
SELECT oi.product_id FROM order_items oi JOIN orders o USING (order_id)
WHERE o.order_date BETWEEN '2025-01-01' AND '2025-03-31'
INTERSECT
SELECT oi.product_id FROM order_items oi JOIN orders o USING (order_id)
WHERE o.order_date BETWEEN '2025-10-01' AND '2025-12-31';

-- Build one contact list from two tables; add a literal column to tell them apart
SELECT first_name || ' ' || last_name AS name, email, 'employee' AS kind FROM employees
UNION ALL
SELECT name, email, 'customer' FROM customers
ORDER BY kind, name;

-- Compare two tables: are they identical?
CREATE TEMP TABLE products_snapshot AS SELECT * FROM products;
UPDATE products_snapshot SET price = 900 WHERE product_id = 2;

(SELECT * FROM products EXCEPT SELECT * FROM products_snapshot)
UNION ALL
(SELECT * FROM products_snapshot EXCEPT SELECT * FROM products);   -- shows both versions of product 2

-- Rule: same number of columns
-- SELECT city, country FROM customers UNION SELECT location FROM departments;
-- ERROR: each UNION query must have the same number of columns
