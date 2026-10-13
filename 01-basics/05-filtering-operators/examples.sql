-- 05 · Filtering operators (PostgreSQL)

-- AND / OR / NOT
SELECT first_name, dept_id, salary FROM employees
WHERE dept_id = 1 AND salary > 100000;

SELECT name, city FROM customers
WHERE city = 'Mumbai' OR city = 'London';

SELECT order_id, status FROM orders
WHERE NOT status = 'delivered';

-- Precedence trap: AND binds tighter than OR
SELECT first_name, dept_id, salary FROM employees
WHERE dept_id = 1 OR dept_id = 2 AND salary > 100000;      -- every dept-1 employee + rich dept-2

SELECT first_name, dept_id, salary FROM employees
WHERE (dept_id = 1 OR dept_id = 2) AND salary > 100000;    -- what was meant

-- IN / NOT IN
SELECT name, country FROM customers WHERE country IN ('UK', 'Spain', 'Germany');
SELECT first_name, dept_id FROM employees WHERE dept_id NOT IN (1, 2);
-- Note: Tom (dept_id NULL) is NOT returned by the line above: NULL NOT IN (1,2) is UNKNOWN.

-- The NOT IN + NULL trap: no rows at all
SELECT dept_name FROM departments
WHERE dept_id NOT IN (SELECT dept_id FROM employees);                 -- 0 rows (list contains NULL)

SELECT dept_name FROM departments d
WHERE NOT EXISTS (SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id);   -- Research

-- BETWEEN is inclusive
SELECT first_name, salary FROM employees WHERE salary BETWEEN 60000 AND 95000;
SELECT order_id, order_date FROM orders WHERE order_date BETWEEN '2025-01-01' AND '2025-03-31';
-- Half-open range: safe for timestamps too
SELECT order_id, order_date FROM orders WHERE order_date >= '2025-01-01' AND order_date < '2025-04-01';

-- LIKE
SELECT first_name FROM employees WHERE first_name LIKE 'A%';      -- starts with A
SELECT first_name FROM employees WHERE first_name LIKE '%a';      -- ends with a
SELECT first_name FROM employees WHERE first_name LIKE '_a%';     -- second letter is a
SELECT product_name FROM products WHERE product_name LIKE '%Desk%';

-- Case sensitivity
SELECT first_name FROM employees WHERE first_name LIKE 'a%';      -- 0 rows in PostgreSQL
SELECT first_name FROM employees WHERE first_name ILIKE 'a%';     -- PostgreSQL only
SELECT first_name FROM employees WHERE LOWER(first_name) LIKE 'a%';  -- portable

-- Regular expression (PostgreSQL): names that start and end with a vowel
SELECT first_name FROM employees WHERE first_name ~* '^[aeiou].*[aeiou]$';

-- IS NULL / IS NOT NULL
SELECT first_name FROM employees WHERE dept_id IS NULL;
SELECT name FROM customers WHERE email IS NOT NULL;
