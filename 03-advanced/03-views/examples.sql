-- 03 · Views and materialized views (PostgreSQL)

-- A view that hides a 3-table join
CREATE OR REPLACE VIEW order_summary AS
SELECT o.order_id,
       o.order_date,
       o.status,
       c.name                           AS customer,
       c.country,
       SUM(oi.quantity * oi.unit_price) AS order_total,
       COUNT(*)                         AS line_items
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
GROUP BY o.order_id, o.order_date, o.status, c.name, c.country;

-- Use it like a table
SELECT * FROM order_summary WHERE country = 'India' ORDER BY order_date;
SELECT country, SUM(order_total) AS revenue FROM order_summary
WHERE status <> 'cancelled' GROUP BY country ORDER BY revenue DESC;

-- A security view: employee directory without salary
CREATE OR REPLACE VIEW employee_directory AS
SELECT e.emp_id, e.first_name, e.last_name, e.email, e.job_title, d.dept_name
FROM employees e
LEFT JOIN departments d ON d.dept_id = e.dept_id;
-- GRANT SELECT ON employee_directory TO reporting_role;  -- (see lesson 13 for roles)
SELECT * FROM employee_directory LIMIT 5;

-- Show a view's definition
SELECT pg_get_viewdef('employee_directory', true);

-- ---------------------------------------------------------------
-- Updatable view + WITH CHECK OPTION
-- ---------------------------------------------------------------
CREATE OR REPLACE VIEW bangalore_depts AS
SELECT dept_id, dept_name, location
FROM departments
WHERE location = 'Bangalore'
WITH CHECK OPTION;

BEGIN;
-- Allowed: the row stays visible through the view
UPDATE bangalore_depts SET dept_name = 'Platform Engineering' WHERE dept_id = 1;
SELECT * FROM departments WHERE dept_id = 1;          -- the base table changed

-- Rejected: the row would disappear from the view
DO $$
BEGIN
    UPDATE bangalore_depts SET location = 'Delhi' WHERE dept_id = 1;
EXCEPTION WHEN with_check_option_violation THEN
    RAISE NOTICE 'Rejected: %', SQLERRM;
END $$;
ROLLBACK;

-- A view with GROUP BY is NOT updatable:
-- UPDATE order_summary SET status = 'shipped' WHERE order_id = 1;
-- ERROR: cannot update view "order_summary" ... Views containing GROUP BY are not automatically updatable.

-- ---------------------------------------------------------------
-- Materialized view
-- ---------------------------------------------------------------
DROP MATERIALIZED VIEW IF EXISTS monthly_revenue;
CREATE MATERIALIZED VIEW monthly_revenue AS
SELECT DATE_TRUNC('month', o.order_date)::DATE AS month,
       SUM(oi.quantity * oi.unit_price)        AS revenue,
       COUNT(DISTINCT o.order_id)              AS orders
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status <> 'cancelled'
GROUP BY 1;

-- It can be indexed like a table (a unique index also enables REFRESH ... CONCURRENTLY)
CREATE UNIQUE INDEX monthly_revenue_month_idx ON monthly_revenue (month);

SELECT * FROM monthly_revenue ORDER BY month;

-- New data is NOT visible until refresh
BEGIN;
INSERT INTO orders VALUES (19, 9, '2026-03-15', 'delivered');
INSERT INTO order_items VALUES (19, 1, 1, 85000);

SELECT * FROM monthly_revenue WHERE month = '2026-03-01';      -- no row yet (order 18 was cancelled)
REFRESH MATERIALIZED VIEW monthly_revenue;
SELECT * FROM monthly_revenue WHERE month = '2026-03-01';      -- 85000 now
ROLLBACK;

-- Clean up
DROP MATERIALIZED VIEW monthly_revenue;
DROP VIEW bangalore_depts;
DROP VIEW employee_directory;
DROP VIEW order_summary;
