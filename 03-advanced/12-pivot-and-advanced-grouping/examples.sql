-- 12 · Pivoting and advanced grouping (PostgreSQL)

-- A reusable base: revenue per order line with category and status
CREATE TEMP VIEW sales AS
SELECT p.category, o.status, c.country,
       EXTRACT(YEAR FROM o.order_date)::INT AS yr,
       EXTRACT(QUARTER FROM o.order_date)::INT AS qtr,
       oi.quantity * oi.unit_price AS revenue
FROM order_items oi
JOIN orders o    ON o.order_id    = oi.order_id
JOIN products p  ON p.product_id  = oi.product_id
JOIN customers c ON c.customer_id = o.customer_id;

-- Long format: one row per (category, status)
SELECT category, status, SUM(revenue) AS revenue
FROM sales
GROUP BY category, status
ORDER BY category, status;

-- ---------------------------------------------------------------
-- Pivot with conditional aggregation (portable)
-- ---------------------------------------------------------------
SELECT category,
       SUM(CASE WHEN status = 'delivered' THEN revenue ELSE 0 END) AS delivered,
       SUM(CASE WHEN status = 'shipped'   THEN revenue ELSE 0 END) AS shipped,
       SUM(CASE WHEN status = 'pending'   THEN revenue ELSE 0 END) AS pending,
       SUM(CASE WHEN status = 'cancelled' THEN revenue ELSE 0 END) AS cancelled,
       SUM(revenue)                                                AS total
FROM sales
GROUP BY category
ORDER BY total DESC;

-- Same pivot with PostgreSQL's FILTER clause
SELECT category,
       COALESCE(SUM(revenue) FILTER (WHERE yr = 2025 AND qtr = 1), 0) AS "2025 Q1",
       COALESCE(SUM(revenue) FILTER (WHERE yr = 2025 AND qtr = 2), 0) AS "2025 Q2",
       COALESCE(SUM(revenue) FILTER (WHERE yr = 2025 AND qtr = 3), 0) AS "2025 Q3",
       COALESCE(SUM(revenue) FILTER (WHERE yr = 2025 AND qtr = 4), 0) AS "2025 Q4",
       COALESCE(SUM(revenue) FILTER (WHERE yr = 2026), 0)             AS "2026"
FROM sales
GROUP BY category
ORDER BY category;

-- ---------------------------------------------------------------
-- Unpivot: columns back into rows
-- ---------------------------------------------------------------
WITH wide AS (
    SELECT category,
           SUM(revenue) FILTER (WHERE status = 'delivered') AS delivered,
           SUM(revenue) FILTER (WHERE status = 'cancelled') AS cancelled
    FROM sales GROUP BY category
)
SELECT w.category, v.status, v.revenue
FROM wide w
CROSS JOIN LATERAL (VALUES ('delivered', w.delivered), ('cancelled', w.cancelled)) AS v(status, revenue)
WHERE v.revenue IS NOT NULL
ORDER BY w.category, v.status;

-- ---------------------------------------------------------------
-- ROLLUP: subtotals per category and a grand total
-- ---------------------------------------------------------------
SELECT CASE WHEN GROUPING(category) = 1 THEN '** ALL **' ELSE category END AS category,
       CASE WHEN GROUPING(status)   = 1 THEN '(subtotal)' ELSE status END   AS status,
       SUM(revenue) AS revenue
FROM sales
GROUP BY ROLLUP (category, status)
ORDER BY GROUPING(category), category, GROUPING(status), status;

-- ---------------------------------------------------------------
-- CUBE: every combination of country and category
-- ---------------------------------------------------------------
SELECT COALESCE(country, 'ALL')  AS country,
       COALESCE(category, 'ALL') AS category,
       SUM(revenue)              AS revenue,
       GROUPING(country, category) AS grouping_level    -- bitmask: 0 detail, 1/2 subtotals, 3 grand total
FROM sales
WHERE status <> 'cancelled'
GROUP BY CUBE (country, category)
ORDER BY grouping_level, country, category;

-- ---------------------------------------------------------------
-- GROUPING SETS: exactly the groupings you want, in one pass
-- ---------------------------------------------------------------
SELECT country, category, yr, SUM(revenue) AS revenue
FROM sales
GROUP BY GROUPING SETS ((country), (category), (yr), ())
ORDER BY country NULLS LAST, category NULLS LAST, yr NULLS LAST;

-- Equivalent with UNION ALL (what you'd write in SQLite)
SELECT country, NULL AS category, NULL::INT AS yr, SUM(revenue) FROM sales GROUP BY country
UNION ALL
SELECT NULL, category, NULL, SUM(revenue) FROM sales GROUP BY category
UNION ALL
SELECT NULL, NULL, yr, SUM(revenue) FROM sales GROUP BY yr
UNION ALL
SELECT NULL, NULL, NULL, SUM(revenue) FROM sales;

-- Headcount and payroll by department and job title, with department subtotals
SELECT COALESCE(d.dept_name, 'No department') AS dept,
       CASE WHEN GROUPING(e.job_title) = 1 THEN 'TOTAL' ELSE e.job_title END AS job_title,
       COUNT(*) AS people,
       SUM(e.salary) AS payroll
FROM employees e
LEFT JOIN departments d ON d.dept_id = e.dept_id
GROUP BY d.dept_name, ROLLUP (e.job_title)
ORDER BY dept, GROUPING(e.job_title), job_title;
