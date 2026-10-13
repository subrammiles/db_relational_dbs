-- =====================================================================
-- Solutions to sql-problems.md (PostgreSQL)
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Second highest salary (NULL if it doesn't exist)
-- ---------------------------------------------------------------------
-- a) Classic: the max of everything below the max. Always returns one row (NULL if none).
SELECT MAX(salary) AS second_highest
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- b) Window function, generalises to N. Wrapping in a scalar subquery returns NULL when missing.
SELECT (
    SELECT DISTINCT salary
    FROM (SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS dr FROM employees) t
    WHERE dr = 2
) AS second_highest;

-- ---------------------------------------------------------------------
-- 2. Nth highest salary (N = 3)
-- ---------------------------------------------------------------------
-- a) DENSE_RANK: ties share a rank, so N counts distinct salaries
WITH ranked AS (
    SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS dr FROM employees
)
SELECT (SELECT DISTINCT salary FROM ranked WHERE dr = 3) AS nth_highest;

-- b) OFFSET on distinct values (N-1 = 2)
SELECT (SELECT DISTINCT salary FROM employees ORDER BY salary DESC OFFSET 2 LIMIT 1) AS nth_highest;

-- c) As a function
CREATE OR REPLACE FUNCTION nth_highest_salary(n INT)
RETURNS NUMERIC
LANGUAGE sql STABLE
AS $$
    SELECT DISTINCT salary FROM employees ORDER BY salary DESC OFFSET n - 1 LIMIT 1;
$$;
SELECT nth_highest_salary(1), nth_highest_salary(3), nth_highest_salary(99);   -- 99 → NULL
DROP FUNCTION nth_highest_salary;

-- ---------------------------------------------------------------------
-- 3. Highest-paid employee(s) per department, with ties
-- ---------------------------------------------------------------------
WITH r AS (
    SELECT dept_id, first_name, salary,
           RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rnk
    FROM employees
    WHERE dept_id IS NOT NULL
)
SELECT d.dept_name, r.first_name, r.salary
FROM r JOIN departments d ON d.dept_id = r.dept_id
WHERE r.rnk = 1
ORDER BY d.dept_name;

-- Without window functions (works on MySQL 5.7)
SELECT e.dept_id, e.first_name, e.salary
FROM employees e
WHERE e.salary = (SELECT MAX(e2.salary) FROM employees e2 WHERE e2.dept_id = e.dept_id);

-- ---------------------------------------------------------------------
-- 4. Top 2 earners per department
-- ---------------------------------------------------------------------
WITH r AS (
    SELECT dept_id, first_name, salary,
           ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC, emp_id) AS rn
    FROM employees
    WHERE dept_id IS NOT NULL
)
SELECT dept_id, first_name, salary FROM r WHERE rn <= 2 ORDER BY dept_id, rn;

-- ---------------------------------------------------------------------
-- 5. Employees who earn more than their manager
-- ---------------------------------------------------------------------
-- (Nobody in the sample data does, so we temporarily create such a case.)
BEGIN;
UPDATE employees SET salary = 200000 WHERE emp_id = 3;    -- Priya now out-earns Vikram (180000)
SELECT e.first_name AS employee, e.salary, m.first_name AS manager, m.salary AS manager_salary
FROM employees e
JOIN employees m ON m.emp_id = e.manager_id
WHERE e.salary > m.salary;
ROLLBACK;

-- ---------------------------------------------------------------------
-- 6. Employees earning more than their department's average
-- ---------------------------------------------------------------------
SELECT first_name, dept_id, salary, ROUND(dept_avg, 0) AS dept_avg
FROM (
    SELECT first_name, dept_id, salary, AVG(salary) OVER (PARTITION BY dept_id) AS dept_avg
    FROM employees
) t
WHERE salary > dept_avg
ORDER BY dept_id;

-- ---------------------------------------------------------------------
-- 7. Departments with no employees
-- ---------------------------------------------------------------------
SELECT d.dept_name
FROM departments d
WHERE NOT EXISTS (SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id);

-- ---------------------------------------------------------------------
-- 8. Customers who never ordered
-- ---------------------------------------------------------------------
SELECT c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- ---------------------------------------------------------------------
-- 9. Managers and their number of direct reports
-- ---------------------------------------------------------------------
SELECT m.first_name AS manager, COUNT(*) AS direct_reports
FROM employees e
JOIN employees m ON m.emp_id = e.manager_id
GROUP BY m.emp_id, m.first_name
ORDER BY direct_reports DESC, manager;

-- ---------------------------------------------------------------------
-- 10. Management chain from each employee to the CEO
-- ---------------------------------------------------------------------
WITH RECURSIVE chain AS (
    SELECT emp_id AS start_id, emp_id, manager_id, first_name::TEXT AS path
    FROM employees
    UNION ALL
    SELECT c.start_id, m.emp_id, m.manager_id, c.path || ' -> ' || m.first_name
    FROM chain c
    JOIN employees m ON m.emp_id = c.manager_id
)
SELECT start_id, path
FROM chain
WHERE manager_id IS NULL          -- reached the top
ORDER BY start_id;

-- ---------------------------------------------------------------------
-- 11. Relational division
-- ---------------------------------------------------------------------
-- a) Customers who ordered in every month of Q1 2025
SELECT customer_id
FROM orders
WHERE order_date >= '2025-01-01' AND order_date < '2025-04-01'
GROUP BY customer_id
HAVING COUNT(DISTINCT DATE_TRUNC('month', order_date)) = 3;   -- (nobody in the sample data)

-- b) Customers who bought EVERY product in the Furniture category that has ever been sold
SELECT o.customer_id
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p     ON p.product_id = oi.product_id
WHERE p.category = 'Furniture'
GROUP BY o.customer_id
HAVING COUNT(DISTINCT oi.product_id) = (
    SELECT COUNT(DISTINCT oi2.product_id)
    FROM order_items oi2 JOIN products p2 ON p2.product_id = oi2.product_id
    WHERE p2.category = 'Furniture'
);

-- ---------------------------------------------------------------------
-- 12. First and last order per customer, days between
-- ---------------------------------------------------------------------
SELECT c.name, MIN(o.order_date) AS first_order, MAX(o.order_date) AS last_order,
       MAX(o.order_date) - MIN(o.order_date) AS days_between
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY days_between DESC;

-- ---------------------------------------------------------------------
-- 13. Month-over-month revenue growth
-- ---------------------------------------------------------------------
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_date)::DATE AS month, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY 1
)
SELECT month, revenue,
       LAG(revenue) OVER (ORDER BY month) AS prev,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month), 1) AS growth_pct
FROM monthly
ORDER BY month;

-- ---------------------------------------------------------------------
-- 14. Running total and the date it first passed 300,000
-- ---------------------------------------------------------------------
WITH daily AS (
    SELECT o.order_date, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY o.order_date
),
running AS (
    SELECT order_date, revenue, SUM(revenue) OVER (ORDER BY order_date) AS running_total
    FROM daily
)
SELECT order_date, running_total
FROM running
WHERE running_total > 300000
ORDER BY order_date
LIMIT 1;

-- ---------------------------------------------------------------------
-- 15. Top category by revenue in each country
-- ---------------------------------------------------------------------
WITH rev AS (
    SELECT c.country, p.category, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM customers c
    JOIN orders o       ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id   = o.order_id
    JOIN products p     ON p.product_id  = oi.product_id
    WHERE o.status <> 'cancelled'
    GROUP BY c.country, p.category
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY country ORDER BY revenue DESC) AS rnk FROM rev
)
SELECT country, category, revenue FROM ranked WHERE rnk = 1 ORDER BY revenue DESC;


-- =====================================================================
-- Problems with their own tables
-- =====================================================================

-- ---------------------------------------------------------------------
-- 16 & 17. Find and delete duplicates
-- ---------------------------------------------------------------------
CREATE TEMP TABLE users (id INT PRIMARY KEY, email VARCHAR(100));
INSERT INTO users VALUES
    (1, 'a@x.com'), (2, 'b@x.com'), (3, 'a@x.com'), (4, 'c@x.com'), (5, 'b@x.com'), (6, 'a@x.com');

-- 16. Find duplicates
SELECT email, COUNT(*) AS copies
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- 17a. Delete duplicates, keep the smallest id (window function)
DELETE FROM users
WHERE id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY email ORDER BY id) AS rn FROM users
    ) t
    WHERE rn > 1
);
SELECT * FROM users ORDER BY id;     -- 1, 2, 4

-- 17b. Same with a self join (works in MySQL: DELETE u1 FROM users u1 JOIN users u2 ...)
INSERT INTO users VALUES (7, 'a@x.com');
DELETE FROM users u1
USING users u2
WHERE u1.email = u2.email AND u1.id > u2.id;
SELECT * FROM users ORDER BY id;     -- 1, 2, 4

-- ---------------------------------------------------------------------
-- 18. Users who logged in on 3+ consecutive days (gaps and islands)
-- ---------------------------------------------------------------------
CREATE TEMP TABLE logins (user_id INT, login_date DATE);
INSERT INTO logins VALUES
    (1, '2025-01-01'), (1, '2025-01-02'), (1, '2025-01-03'), (1, '2025-01-05'),
    (2, '2025-01-01'), (2, '2025-01-03'), (2, '2025-01-04'),
    (3, '2025-01-10'), (3, '2025-01-11'), (3, '2025-01-11'), (3, '2025-01-12'), (3, '2025-01-13');

-- Trick: for consecutive dates, date - row_number is constant. Same constant = same streak.
WITH d AS (
    SELECT DISTINCT user_id, login_date FROM logins          -- duplicate logins on a day count once
),
grp AS (
    SELECT user_id, login_date,
           login_date - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY login_date))::INT AS streak_key
    FROM d
)
SELECT user_id, MIN(login_date) AS streak_start, MAX(login_date) AS streak_end, COUNT(*) AS days
FROM grp
GROUP BY user_id, streak_key
HAVING COUNT(*) >= 3
ORDER BY user_id;          -- user 1 (3 days), user 3 (4 days)

-- ---------------------------------------------------------------------
-- 19. Missing ids in a sequence
-- ---------------------------------------------------------------------
CREATE TEMP TABLE invoices (invoice_no INT PRIMARY KEY);
INSERT INTO invoices VALUES (1), (2), (3), (6), (7), (10);

-- a) Every missing number
SELECT g AS missing
FROM generate_series((SELECT MIN(invoice_no) FROM invoices), (SELECT MAX(invoice_no) FROM invoices)) g
WHERE NOT EXISTS (SELECT 1 FROM invoices WHERE invoice_no = g);     -- 4, 5, 8, 9

-- b) Gaps as ranges, portable (LEAD)
SELECT invoice_no + 1 AS gap_start, next_no - 1 AS gap_end
FROM (SELECT invoice_no, LEAD(invoice_no) OVER (ORDER BY invoice_no) AS next_no FROM invoices) t
WHERE next_no - invoice_no > 1;                                     -- 4-5, 8-9

-- ---------------------------------------------------------------------
-- 20. Islands: consecutive rows with the same status as ranges
-- ---------------------------------------------------------------------
CREATE TEMP TABLE server_status (minute INT, status VARCHAR(4));
INSERT INTO server_status VALUES
    (1,'up'), (2,'up'), (3,'down'), (4,'down'), (5,'down'), (6,'up'), (7,'down'), (8,'up'), (9,'up');

WITH g AS (
    SELECT minute, status,
           ROW_NUMBER() OVER (ORDER BY minute)
         - ROW_NUMBER() OVER (PARTITION BY status ORDER BY minute) AS island
    FROM server_status
)
SELECT status, MIN(minute) AS from_minute, MAX(minute) AS to_minute, COUNT(*) AS minutes
FROM g
GROUP BY status, island
ORDER BY from_minute;

-- ---------------------------------------------------------------------
-- 21. Swap 'M' and 'F' in one UPDATE
-- ---------------------------------------------------------------------
CREATE TEMP TABLE people (id INT, sex CHAR(1));
INSERT INTO people VALUES (1, 'M'), (2, 'F'), (3, 'M');
UPDATE people SET sex = CASE sex WHEN 'M' THEN 'F' WHEN 'F' THEN 'M' ELSE sex END;
SELECT * FROM people ORDER BY id;

-- ---------------------------------------------------------------------
-- 22. Pivot student marks
-- ---------------------------------------------------------------------
CREATE TEMP TABLE marks (student VARCHAR(10), subject VARCHAR(10), score INT);
INSERT INTO marks VALUES
    ('Ana', 'Math', 90), ('Ana', 'Science', 85), ('Ana', 'English', 70),
    ('Ben', 'Math', 60), ('Ben', 'English', 95);

SELECT student,
       MAX(CASE WHEN subject = 'Math'    THEN score END) AS math,
       MAX(CASE WHEN subject = 'Science' THEN score END) AS science,
       MAX(CASE WHEN subject = 'English' THEN score END) AS english
FROM marks
GROUP BY student
ORDER BY student;

-- ---------------------------------------------------------------------
-- 23. Median order value per customer
-- ---------------------------------------------------------------------
WITH order_totals AS (
    SELECT o.customer_id, o.order_id, SUM(oi.quantity * oi.unit_price) AS total
    FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id, o.order_id
)
SELECT customer_id,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total) AS median_order
FROM order_totals
GROUP BY customer_id
ORDER BY customer_id;

-- Without PERCENTILE_CONT (e.g. MySQL 8): average the middle one or two rows
WITH order_totals AS (
    SELECT o.customer_id, SUM(oi.quantity * oi.unit_price) AS total
    FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id, o.order_id
),
numbered AS (
    SELECT customer_id, total,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total) AS rn,
           COUNT(*)     OVER (PARTITION BY customer_id)                AS cnt
    FROM order_totals
)
SELECT customer_id, ROUND(AVG(total), 2) AS median_order
FROM numbered
WHERE rn IN ((cnt + 1) / 2, (cnt + 2) / 2)
GROUP BY customer_id
ORDER BY customer_id;

-- ---------------------------------------------------------------------
-- 24. Friend recommendations: friends of friends who aren't friends yet
-- ---------------------------------------------------------------------
CREATE TEMP TABLE friendships (a INT, b INT);          -- stored once per pair
INSERT INTO friendships VALUES (1, 2), (1, 3), (2, 4), (3, 4), (4, 5);

WITH f AS (                                            -- make it symmetric
    SELECT a AS person, b AS friend FROM friendships
    UNION
    SELECT b, a FROM friendships
)
SELECT f1.person, f2.friend AS suggestion, COUNT(*) AS mutual_friends
FROM f f1
JOIN f f2 ON f2.person = f1.friend
WHERE f2.friend <> f1.person
  AND NOT EXISTS (SELECT 1 FROM f WHERE f.person = f1.person AND f.friend = f2.friend)
GROUP BY f1.person, f2.friend
ORDER BY f1.person, mutual_friends DESC, suggestion;

-- ---------------------------------------------------------------------
-- 25. Month-1 → month-2 retention
-- ---------------------------------------------------------------------
CREATE TEMP TABLE activity (user_id INT, active_on DATE);
INSERT INTO activity VALUES
    (1, '2025-01-03'), (1, '2025-02-10'),
    (2, '2025-01-15'),
    (3, '2025-01-20'), (3, '2025-01-25'), (3, '2025-02-01'),
    (4, '2025-02-05');

WITH m AS (
    SELECT DISTINCT user_id, DATE_TRUNC('month', active_on)::DATE AS month FROM activity
)
SELECT cur.month,
       COUNT(*)                         AS active_users,
       COUNT(nxt.user_id)               AS retained_next_month,
       ROUND(100.0 * COUNT(nxt.user_id) / COUNT(*), 1) AS retention_pct
FROM m cur
LEFT JOIN m nxt ON nxt.user_id = cur.user_id AND nxt.month = (cur.month + INTERVAL '1 month')::DATE
WHERE cur.month = '2025-01-01'
GROUP BY cur.month;                    -- 3 active in Jan, 2 came back → 66.7%

-- ---------------------------------------------------------------------
-- 26. Rank scores without gaps
-- ---------------------------------------------------------------------
CREATE TEMP TABLE scores (id INT, score NUMERIC(4,2));
INSERT INTO scores VALUES (1, 3.50), (2, 3.65), (3, 4.00), (4, 3.85), (5, 4.00), (6, 3.65);
SELECT score, DENSE_RANK() OVER (ORDER BY score DESC) AS rank FROM scores ORDER BY score DESC;

-- ---------------------------------------------------------------------
-- 27. Numbers appearing at least 3 times consecutively
-- ---------------------------------------------------------------------
CREATE TEMP TABLE logs (id INT PRIMARY KEY, num INT);
INSERT INTO logs VALUES (1, 1), (2, 1), (3, 1), (4, 2), (5, 1), (6, 2), (7, 2), (8, 2);

SELECT DISTINCT num
FROM (
    SELECT num,
           LAG(num)  OVER (ORDER BY id) AS prev_num,
           LEAD(num) OVER (ORDER BY id) AS next_num
    FROM logs
) t
WHERE num = prev_num AND num = next_num;     -- 1 and 2

-- ---------------------------------------------------------------------
-- 28. Running balance per account and the first time it went negative
-- ---------------------------------------------------------------------
CREATE TEMP TABLE ledger (account INT, txn_time TIMESTAMP, amount NUMERIC);
INSERT INTO ledger VALUES
    (1, '2025-01-01 09:00', 100), (1, '2025-01-02 09:00', -150), (1, '2025-01-03 09:00', 200),
    (2, '2025-01-01 10:00',  50), (2, '2025-01-04 10:00',  -20);

WITH running AS (
    SELECT account, txn_time, amount,
           SUM(amount) OVER (PARTITION BY account ORDER BY txn_time) AS balance
    FROM ledger
)
SELECT account, MIN(txn_time) AS first_negative
FROM running
WHERE balance < 0
GROUP BY account;                            -- account 1 at 2025-01-02 09:00
