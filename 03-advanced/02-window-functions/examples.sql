-- 02 · Window functions (PostgreSQL)

-- Aggregate as a window: each employee next to department figures
SELECT first_name, dept_id, salary,
       ROUND(AVG(salary) OVER (PARTITION BY dept_id), 0) AS dept_avg,
       MAX(salary)       OVER (PARTITION BY dept_id)      AS dept_max,
       COUNT(*)          OVER (PARTITION BY dept_id)      AS dept_size,
       ROUND(100.0 * salary / SUM(salary) OVER (PARTITION BY dept_id), 1) AS pct_of_dept,
       SUM(salary)       OVER ()                          AS company_payroll
FROM employees
ORDER BY dept_id, salary DESC;

-- Ranking: the difference shows on the tied salaries (95000 x2, 70000 x2)
SELECT first_name, salary,
       ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
       RANK()       OVER (ORDER BY salary DESC) AS rnk,
       DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rnk,
       NTILE(4)     OVER (ORDER BY salary DESC) AS quartile
FROM employees
ORDER BY salary DESC;

-- Ranking within each department
SELECT dept_id, first_name, salary,
       DENSE_RANK() OVER (PARTITION BY dept_id ORDER BY salary DESC) AS rank_in_dept
FROM employees
WHERE dept_id IS NOT NULL
ORDER BY dept_id, rank_in_dept;

-- Filtering on a window result needs a subquery / CTE.
-- Top 2 earners per department:
WITH ranked AS (
    SELECT dept_id, first_name, salary,
           ROW_NUMBER() OVER (PARTITION BY dept_id ORDER BY salary DESC, emp_id) AS rn
    FROM employees
    WHERE dept_id IS NOT NULL
)
SELECT dept_id, first_name, salary FROM ranked WHERE rn <= 2 ORDER BY dept_id, rn;

-- 3rd highest distinct salary
SELECT DISTINCT salary
FROM (SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS dr FROM employees) t
WHERE dr = 3;

-- ---------------------------------------------------------------
-- Running totals and moving averages over monthly revenue
-- ---------------------------------------------------------------
WITH monthly AS (
    SELECT DATE_TRUNC('month', o.order_date)::DATE AS month,
           SUM(oi.quantity * oi.unit_price)        AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY 1
)
SELECT month,
       revenue,
       SUM(revenue) OVER (ORDER BY month)                                   AS running_total,
       ROUND(AVG(revenue) OVER (ORDER BY month
                                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS moving_avg_3,
       LAG(revenue)  OVER (ORDER BY month)                                  AS prev_month,
       revenue - LAG(revenue) OVER (ORDER BY month)                         AS change,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1)                       AS pct_change,
       LEAD(revenue) OVER (ORDER BY month)                                  AS next_month,
       ROUND(100.0 * SUM(revenue) OVER (ORDER BY month) / SUM(revenue) OVER (), 1) AS cumulative_pct
FROM monthly
ORDER BY month;

-- LAG per partition: days since each customer's previous order
SELECT customer_id, order_id, order_date,
       LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order,
       order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_between
FROM orders
ORDER BY customer_id, order_date;

-- FIRST_VALUE / LAST_VALUE and the frame gotcha
SELECT dept_id, first_name, salary,
       FIRST_VALUE(first_name) OVER (PARTITION BY dept_id ORDER BY salary DESC) AS top_earner,
       LAST_VALUE(first_name)  OVER (PARTITION BY dept_id ORDER BY salary DESC) AS last_value_wrong,
       LAST_VALUE(first_name)  OVER (PARTITION BY dept_id ORDER BY salary DESC
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS lowest_earner
FROM employees
WHERE dept_id IN (1, 2)
ORDER BY dept_id, salary DESC;

-- ROWS vs RANGE: tied salaries are "peers" under RANGE
SELECT first_name, salary,
       SUM(salary) OVER (ORDER BY salary ROWS  BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rows_total,
       SUM(salary) OVER (ORDER BY salary RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS range_total
FROM employees
WHERE salary BETWEEN 60000 AND 100000
ORDER BY salary, emp_id;

-- Window over an aggregate: each category's revenue and its share of all revenue
SELECT p.category,
       SUM(oi.quantity * oi.unit_price) AS revenue,
       ROUND(100.0 * SUM(oi.quantity * oi.unit_price)
             / SUM(SUM(oi.quantity * oi.unit_price)) OVER (), 1) AS pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Named window (WINDOW clause) used by several functions
SELECT first_name, dept_id, salary,
       RANK()      OVER w AS rnk,
       PERCENT_RANK() OVER w AS pct_rank,
       CUME_DIST() OVER w AS cume_dist
FROM employees
WHERE dept_id = 1
WINDOW w AS (PARTITION BY dept_id ORDER BY salary);

-- ERROR: window functions are not allowed in WHERE
-- SELECT first_name FROM employees WHERE ROW_NUMBER() OVER (ORDER BY salary) = 1;
