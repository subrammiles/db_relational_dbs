-- 06 · ORDER BY, LIMIT and pagination (PostgreSQL)

-- Ascending (default) and descending
SELECT first_name, salary FROM employees ORDER BY salary;
SELECT first_name, salary FROM employees ORDER BY salary DESC;

-- Several sort keys: department, then highest salary first inside each department
SELECT dept_id, first_name, salary FROM employees ORDER BY dept_id, salary DESC;

-- Sort by an alias or an expression
SELECT first_name, salary * 12 AS annual FROM employees ORDER BY annual DESC;
SELECT first_name, last_name FROM employees ORDER BY LENGTH(last_name), last_name;

-- NULL placement: PostgreSQL puts NULLs last for ASC; Tom (no dept) is last here...
SELECT first_name, dept_id FROM employees ORDER BY dept_id;
-- ...and first here
SELECT first_name, dept_id FROM employees ORDER BY dept_id NULLS FIRST;

-- Top N
SELECT first_name, salary FROM employees ORDER BY salary DESC LIMIT 3;
SELECT first_name, salary FROM employees ORDER BY salary DESC FETCH FIRST 3 ROWS ONLY;   -- standard SQL

-- WITH TIES: returns 8 rows, because the 7th salary (95000) is shared by Rahul and Sneha
SELECT first_name, salary FROM employees ORDER BY salary DESC FETCH FIRST 7 ROWS WITH TIES;

-- Offset pagination: page 2, 5 rows per page
SELECT order_id, order_date FROM orders ORDER BY order_id LIMIT 5 OFFSET 5;
SELECT order_id, order_date FROM orders ORDER BY order_id OFFSET 5 ROWS FETCH NEXT 5 ROWS ONLY;

-- Keyset pagination: "give me the 5 orders after order 10"
SELECT order_id, order_date FROM orders WHERE order_id > 10 ORDER BY order_id LIMIT 5;

-- Paginating on a non-unique column: add a unique tie-breaker
SELECT order_id, customer_id, order_date FROM orders
ORDER BY customer_id, order_id
LIMIT 5;
