-- 04 · Exercises with solutions

-- 1. Show the name and price of every product.
SELECT product_name, price FROM products;

-- 2. Show the products that cost less than 1000.
SELECT product_name, price FROM products WHERE price < 1000;

-- 3. Show every order that has status 'cancelled'.
SELECT * FROM orders WHERE status = 'cancelled';

-- 4. Show each product with its stock value (price * stock) as `stock_value`.
SELECT product_name, price * stock AS stock_value FROM products;

-- 5. Show customers who have no email address.
SELECT name FROM customers WHERE email IS NULL;

-- 6. Show employees hired before 2018.
SELECT first_name, last_name, hire_date FROM employees WHERE hire_date < '2018-01-01';
