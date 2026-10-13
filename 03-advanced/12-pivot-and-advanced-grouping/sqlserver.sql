-- 12 · PIVOT, UNPIVOT and ROLLUP in SQL Server (T-SQL)

-- PIVOT: revenue per category with a column per status
SELECT category, [delivered], [shipped], [pending], [cancelled]
FROM (
    SELECT p.category, o.status, oi.quantity * oi.unit_price AS revenue
    FROM order_items oi
    JOIN orders o   ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
) src
PIVOT (SUM(revenue) FOR status IN ([delivered], [shipped], [pending], [cancelled])) AS pv
ORDER BY category;

-- UNPIVOT: columns back to rows
SELECT product_name, measure, value
FROM (SELECT product_name, CAST(price AS DECIMAL(12,2)) AS price, CAST(stock AS DECIMAL(12,2)) AS stock
      FROM products WHERE product_id <= 3) src
UNPIVOT (value FOR measure IN (price, stock)) AS up;

-- Dynamic PIVOT: build the column list from the data
DECLARE @cols NVARCHAR(MAX), @sql NVARCHAR(MAX);
SELECT @cols = STRING_AGG(QUOTENAME(country), ', ') WITHIN GROUP (ORDER BY country)
FROM (SELECT DISTINCT country FROM customers) c;

SET @sql = N'SELECT category, ' + @cols + N'
FROM (
    SELECT p.category, c.country, oi.quantity * oi.unit_price AS revenue
    FROM order_items oi
    JOIN orders o    ON o.order_id = oi.order_id
    JOIN customers c ON c.customer_id = o.customer_id
    JOIN products p  ON p.product_id = oi.product_id
) src
PIVOT (SUM(revenue) FOR country IN (' + @cols + N')) pv;';
EXEC sp_executesql @sql;

-- ROLLUP / CUBE / GROUPING SETS / GROUPING()
SELECT CASE WHEN GROUPING(p.category) = 1 THEN 'ALL' ELSE p.category END AS category,
       CASE WHEN GROUPING(o.status)   = 1 THEN 'subtotal' ELSE o.status END AS status,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY ROLLUP (p.category, o.status)
ORDER BY GROUPING(p.category), p.category, GROUPING(o.status), o.status;
