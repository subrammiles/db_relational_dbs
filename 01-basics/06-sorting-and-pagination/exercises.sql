-- 06 · Exercises with solutions

-- 1. The 3 most expensive products.
SELECT product_name, price FROM products ORDER BY price DESC LIMIT 3;

-- 2. Customers sorted by country, then by name.
SELECT name, country FROM customers ORDER BY country, name;

-- 3. The most recently hired employee.
SELECT first_name, last_name, hire_date FROM employees ORDER BY hire_date DESC LIMIT 1;

-- 4. Page 3 of products, 3 per page, ordered by product_id.
SELECT product_id, product_name FROM products ORDER BY product_id LIMIT 3 OFFSET 6;

-- 5. Customers with their email, those without an email listed first.
SELECT name, email FROM customers ORDER BY email NULLS FIRST, name;
