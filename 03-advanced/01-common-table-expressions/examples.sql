-- 01 · CTEs and recursive queries (PostgreSQL)

-- A simple CTE: employees earning more than their department's average
WITH dept_avg AS (
    SELECT dept_id, AVG(salary) AS avg_salary
    FROM employees
    GROUP BY dept_id
)
SELECT e.first_name, e.dept_id, e.salary, ROUND(d.avg_salary, 0) AS dept_avg
FROM employees e
JOIN dept_avg d ON d.dept_id = e.dept_id
WHERE e.salary > d.avg_salary
ORDER BY e.dept_id;

-- Several CTEs chained as steps: revenue per customer → classify → summarise
WITH order_totals AS (
    SELECT o.order_id, o.customer_id, SUM(oi.quantity * oi.unit_price) AS total
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY o.order_id, o.customer_id
),
customer_revenue AS (
    SELECT customer_id, COUNT(*) AS orders, SUM(total) AS revenue
    FROM order_totals
    GROUP BY customer_id
),
segmented AS (
    SELECT customer_id, orders, revenue,
           CASE WHEN revenue >= 100000 THEN 'Gold'
                WHEN revenue >=  20000 THEN 'Silver'
                ELSE 'Bronze' END AS segment
    FROM customer_revenue
)
SELECT segment, COUNT(*) AS customers, SUM(revenue) AS revenue
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;

-- The same CTE referenced twice
WITH payroll AS (
    SELECT dept_id, SUM(salary) AS total FROM employees WHERE dept_id IS NOT NULL GROUP BY dept_id
)
SELECT d.dept_name, p.total,
       ROUND(100.0 * p.total / (SELECT SUM(total) FROM payroll), 1) AS pct
FROM payroll p
JOIN departments d ON d.dept_id = p.dept_id
ORDER BY p.total DESC;

-- ---------------------------------------------------------------
-- Recursive CTEs
-- ---------------------------------------------------------------

-- 1. Org chart: every employee with their level and the path from the CEO
WITH RECURSIVE org AS (
    SELECT emp_id, first_name, manager_id, 1 AS level,
           first_name::TEXT AS path
    FROM employees
    WHERE manager_id IS NULL                        -- anchor: the CEO

    UNION ALL

    SELECT e.emp_id, e.first_name, e.manager_id, o.level + 1,
           o.path || ' > ' || e.first_name
    FROM employees e
    JOIN org o ON e.manager_id = o.emp_id           -- recursive step
)
SELECT LPAD('', (level - 1) * 4, ' ') || first_name AS org_chart, level, path
FROM org
ORDER BY path;

-- 2. Walk UP: the management chain above Arjun (emp 6)
WITH RECURSIVE chain AS (
    SELECT emp_id, first_name, manager_id, 0 AS steps_up
    FROM employees WHERE emp_id = 6
    UNION ALL
    SELECT m.emp_id, m.first_name, m.manager_id, c.steps_up + 1
    FROM employees m
    JOIN chain c ON m.emp_id = c.manager_id
)
SELECT * FROM chain ORDER BY steps_up;

-- 3. Everyone under Vikram (emp 2), directly or indirectly, with the total cost
WITH RECURSIVE team AS (
    SELECT emp_id, salary FROM employees WHERE manager_id = 2
    UNION ALL
    SELECT e.emp_id, e.salary FROM employees e JOIN team t ON e.manager_id = t.emp_id
)
SELECT COUNT(*) AS team_size, SUM(salary) AS team_cost FROM team;

-- 4. Generate a series: every month of 2025 (no table needed)
WITH RECURSIVE months AS (
    SELECT DATE '2025-01-01' AS month
    UNION ALL
    SELECT (month + INTERVAL '1 month')::DATE FROM months WHERE month < DATE '2025-12-01'
)
-- ...and LEFT JOIN orders so empty months show 0
SELECT m.month, COUNT(o.order_id) AS orders
FROM months m
LEFT JOIN orders o ON DATE_TRUNC('month', o.order_date) = m.month
GROUP BY m.month
ORDER BY m.month;

-- PostgreSQL shortcut for series
SELECT generate_series(1, 5) AS n;

-- 5. Cycle protection: a graph with a loop A → B → C → A
WITH RECURSIVE edges(src, dst) AS (
    VALUES ('A', 'B'), ('B', 'C'), ('C', 'A'), ('C', 'D')
),
walk AS (
    SELECT 'A'::TEXT AS node, ARRAY['A']::TEXT[] AS visited
    UNION ALL
    SELECT e.dst, w.visited || e.dst
    FROM walk w
    JOIN edges e ON e.src = w.node
    WHERE NOT e.dst = ANY (w.visited)               -- stop when we'd revisit a node
)
SELECT node, array_to_string(visited, ' > ') AS route FROM walk;

-- ---------------------------------------------------------------
-- Data-modifying CTE (PostgreSQL): archive cancelled orders in one statement
-- ---------------------------------------------------------------
BEGIN;
CREATE TEMP TABLE orders_archive (LIKE orders);
WITH moved AS (
    DELETE FROM orders WHERE status = 'cancelled' RETURNING *
)
INSERT INTO orders_archive SELECT * FROM moved;
SELECT * FROM orders_archive;
ROLLBACK;
