-- 05 · Exercises with solutions

-- 1. Electronics products priced between 2000 and 20000 (inclusive).
SELECT product_name, price FROM products
WHERE category = 'Electronics' AND price BETWEEN 2000 AND 20000;

-- 2. Customers from India or the UK who signed up in 2024.
SELECT name, country, signup_date FROM customers
WHERE country IN ('India', 'UK')
  AND signup_date >= '2024-01-01' AND signup_date < '2025-01-01';

-- 3. Employees whose last name contains the letter 'r' (any case).
SELECT first_name, last_name FROM employees WHERE last_name ILIKE '%r%';

-- 4. Orders that are neither delivered nor cancelled.
SELECT order_id, status FROM orders WHERE status NOT IN ('delivered', 'cancelled');

-- 5. Employees who are not managed by anyone (the top of the hierarchy).
SELECT first_name, last_name FROM employees WHERE manager_id IS NULL;

-- 6. Products whose name is exactly 9 characters long, using LIKE only.
SELECT product_name FROM products WHERE product_name LIKE '_________';
