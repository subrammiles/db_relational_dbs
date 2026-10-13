-- 02 · Exercises with solutions

-- 1. Number each customer's orders 1, 2, 3... by date.
SELECT customer_id, order_id, order_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_seq
FROM orders
ORDER BY customer_id, order_seq;

-- 2. Each customer's first order only.
WITH numbered AS (
    SELECT customer_id, order_id, order_date,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS rn
    FROM orders
)
SELECT customer_id, order_id, order_date FROM numbered WHERE rn = 1;

-- 3. The most expensive product in each category, with ties.
WITH r AS (
    SELECT category, product_name, price,
           RANK() OVER (PARTITION BY category ORDER BY price DESC) AS rnk
    FROM products
)
SELECT category, product_name, price FROM r WHERE rnk = 1;

-- 4. Each employee's salary and the difference to the next-higher salary in their department.
SELECT dept_id, first_name, salary,
       LAG(salary) OVER (PARTITION BY dept_id ORDER BY salary DESC) - salary AS gap_to_next_higher
FROM employees
WHERE dept_id IS NOT NULL
ORDER BY dept_id, salary DESC;

-- 5. Running count of customer signups over time.
SELECT name, signup_date,
       COUNT(*) OVER (ORDER BY signup_date) AS customers_so_far
FROM customers
ORDER BY signup_date;

-- 6. Order totals with the customer's lifetime total on every row and the order's share of it.
WITH t AS (
    SELECT o.customer_id, o.order_id, SUM(oi.quantity * oi.unit_price) AS order_total
    FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id, o.order_id
)
SELECT customer_id, order_id, order_total,
       SUM(order_total) OVER (PARTITION BY customer_id) AS lifetime,
       ROUND(100.0 * order_total / SUM(order_total) OVER (PARTITION BY customer_id), 1) AS pct
FROM t
ORDER BY customer_id, order_id;
