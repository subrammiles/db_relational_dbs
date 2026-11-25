-- 09 · Exercises with solutions

-- 1. Orders placed in February 2025, written so an index on order_date could be used.
SELECT order_id, customer_id, order_date
FROM orders
WHERE order_date >= DATE '2025-02-01' AND order_date < DATE '2025-03-01';

-- 2. Revenue for every month from January 2025 to March 2026, showing 0 for months
--    with no (non-cancelled) orders.
WITH months AS (
    SELECT generate_series(DATE '2025-01-01', DATE '2026-03-01', INTERVAL '1 month')::date AS month
)
SELECT TO_CHAR(m.month, 'YYYY-MM') AS month,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS revenue
FROM months m
LEFT JOIN orders o       ON o.order_date >= m.month AND o.order_date < m.month + INTERVAL '1 month'
                        AND o.status <> 'cancelled'
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY m.month
ORDER BY m.month;

-- 3. Each employee's next work anniversary (the next date, on or after today,
--    with the same month and day as hire_date).
SELECT first_name, hire_date,
       CASE WHEN (hire_date + full_years * INTERVAL '1 year')::date >= CURRENT_DATE
            THEN (hire_date + full_years * INTERVAL '1 year')::date
            ELSE (hire_date + (full_years + 1) * INTERVAL '1 year')::date
       END AS next_anniversary
FROM (
    SELECT first_name, hire_date,
           EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date))::int AS full_years
    FROM employees
) e
ORDER BY next_anniversary;

-- 4. Number of orders per weekday name (Monday first), across all orders.
SELECT TO_CHAR(order_date, 'FMDay') AS weekday, COUNT(*) AS orders
FROM orders
GROUP BY TO_CHAR(order_date, 'FMDay'), EXTRACT(ISODOW FROM order_date)
ORDER BY EXTRACT(ISODOW FROM order_date);

-- 5. For each customer, the number of days between consecutive orders.
SELECT customer_id, order_id, order_date,
       order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS days_since_previous
FROM orders
ORDER BY customer_id, order_date;

-- 6. A shop in Mumbai stores payments in UTC. Count payments per LOCAL (Asia/Kolkata) day.
CREATE TEMP TABLE payments (payment_id INT, paid_at TIMESTAMPTZ, amount NUMERIC);
INSERT INTO payments VALUES
    (1, '2025-06-01 03:00+00', 500),    -- 08:30 on 1 June local
    (2, '2025-06-01 18:45+00', 250),    -- 00:15 on 2 June local
    (3, '2025-06-02 10:00+00', 100);

SELECT (paid_at AT TIME ZONE 'Asia/Kolkata')::date AS local_day,
       COUNT(*) AS payments, SUM(amount) AS total
FROM payments
GROUP BY 1
ORDER BY 1;                                       -- 1 June: 1 payment; 2 June: 2 payments

-- 7. A meeting is at 09:00 in New York on 10 March 2025. What time is it in London and in India?
SELECT (TIMESTAMP '2025-03-10 09:00' AT TIME ZONE 'America/New_York') AT TIME ZONE 'Europe/London' AS london,
       (TIMESTAMP '2025-03-10 09:00' AT TIME ZONE 'America/New_York') AT TIME ZONE 'Asia/Kolkata'  AS india;
-- London 13:00 (not 14:00: the US had already switched to DST, the UK hadn't yet), India 18:30.

-- 8. Find shifts that overlap another shift for the same employee.
CREATE TEMP TABLE shifts (shift_id INT, emp_id INT, start_at TIMESTAMP, end_at TIMESTAMP);
INSERT INTO shifts VALUES
    (1, 1, '2025-06-01 08:00', '2025-06-01 16:00'),
    (2, 1, '2025-06-01 15:00', '2025-06-01 23:00'),   -- overlaps 1
    (3, 1, '2025-06-02 08:00', '2025-06-02 16:00'),
    (4, 2, '2025-06-01 16:00', '2025-06-02 00:00'),
    (5, 2, '2025-06-02 00:00', '2025-06-02 08:00');   -- touches 4, no overlap

SELECT a.emp_id, a.shift_id, b.shift_id AS overlaps_with
FROM shifts a
JOIN shifts b ON a.emp_id = b.emp_id
             AND a.shift_id < b.shift_id
             AND a.start_at < b.end_at
             AND b.start_at < a.end_at;               -- (1, 1, 2)

-- 9. Average order value per ISO week of 2025, labelled like '2025-W03'.
SELECT TO_CHAR(o.order_date, 'IYYY-"W"IW') AS iso_week,
       ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_date >= DATE '2025-01-01' AND o.order_date < DATE '2026-01-01'
GROUP BY 1
ORDER BY 1;
