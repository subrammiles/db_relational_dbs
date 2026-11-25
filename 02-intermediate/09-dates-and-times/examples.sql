-- 09 · Dates, times and time zones (PostgreSQL)

-- ---------------------------------------------------------------
-- TIMESTAMP vs TIMESTAMPTZ
-- ---------------------------------------------------------------
SET TIME ZONE 'UTC';

CREATE TEMP TABLE tz_demo (
    label    TEXT,
    wall     TIMESTAMP,      -- no zone: stored exactly as typed
    instant  TIMESTAMPTZ     -- converted to UTC on the way in
);
INSERT INTO tz_demo VALUES
    ('typed in UTC',     '2025-06-01 12:00', '2025-06-01 12:00+00'),
    ('typed in India',   '2025-06-01 12:00', '2025-06-01 12:00+05:30');

SELECT * FROM tz_demo;              -- `wall` identical; `instant` differs by 5h30

SET TIME ZONE 'Asia/Tokyo';
SELECT * FROM tz_demo;              -- `wall` unchanged; `instant` now displayed in Tokyo time
SET TIME ZONE 'UTC';

-- ---------------------------------------------------------------
-- AT TIME ZONE works in both directions
-- ---------------------------------------------------------------
SELECT TIMESTAMPTZ '2025-06-01 12:00+00' AT TIME ZONE 'Asia/Tokyo'  AS tokyo_wall_clock,  -- TIMESTAMP 21:00
       TIMESTAMP   '2025-06-01 21:00'    AT TIME ZONE 'Asia/Tokyo'  AS instant;           -- TIMESTAMPTZ 12:00 UTC

-- Zone names know about DST; fixed offsets don't.
SELECT TIMESTAMPTZ '2025-01-15 12:00+00' AT TIME ZONE 'Europe/London' AS london_winter,   -- 12:00
       TIMESTAMPTZ '2025-07-15 12:00+00' AT TIME ZONE 'Europe/London' AS london_summer;   -- 13:00

-- The POSIX sign trap: 'UTC+5' means five hours WEST of UTC.
SELECT TIMESTAMPTZ '2025-06-01 12:00+00' AT TIME ZONE 'UTC+5'        AS posix_utc_plus_5,  -- 07:00 (!)
       TIMESTAMPTZ '2025-06-01 12:00+00' AT TIME ZONE 'Asia/Karachi' AS karachi;           -- 17:00

-- ---------------------------------------------------------------
-- Daylight saving time: '1 day' vs '24 hours'
-- ---------------------------------------------------------------
SET TIME ZONE 'America/New_York';
SELECT TIMESTAMPTZ '2025-03-08 12:00' + INTERVAL '1 day'    AS same_clock_time,   -- 2025-03-09 12:00-04
       TIMESTAMPTZ '2025-03-08 12:00' + INTERVAL '24 hours' AS exactly_24h;       -- 2025-03-09 13:00-04

-- How long was 9 March 2025 in New York?
SELECT TIMESTAMPTZ '2025-03-10 00:00' - TIMESTAMPTZ '2025-03-09 00:00' AS length_of_day;   -- 23:00:00
SET TIME ZONE 'UTC';

-- ---------------------------------------------------------------
-- Half-open date ranges
-- ---------------------------------------------------------------
-- Orders in Q1 2025: start inclusive, end exclusive.
SELECT order_id, order_date
FROM orders
WHERE order_date >= DATE '2025-01-01' AND order_date < DATE '2025-04-01'
ORDER BY order_date;

-- Why BETWEEN breaks with a time part:
CREATE TEMP TABLE logins (user_id INT, login_at TIMESTAMP);
INSERT INTO logins VALUES (1, '2025-01-31 09:15'), (2, '2025-01-31 00:00'), (3, '2025-02-01 00:00');

SELECT COUNT(*) AS between_count FROM logins
WHERE login_at BETWEEN '2025-01-01' AND '2025-01-31';               -- 1: misses the 09:15 login

SELECT COUNT(*) AS half_open_count FROM logins
WHERE login_at >= '2025-01-01' AND login_at < '2025-02-01';         -- 2: correct

-- ---------------------------------------------------------------
-- Month arithmetic
-- ---------------------------------------------------------------
SELECT DATE '2025-01-31' + INTERVAL '1 month'                        AS plus_month,        -- 2025-02-28
       DATE '2025-01-31' + INTERVAL '1 month' - INTERVAL '1 month'   AS and_back,          -- 2025-01-28
       DATE '2024-02-29' + INTERVAL '1 year'                         AS leap_plus_year;    -- 2025-02-28

-- Monthly billing dates: always add n months to the ORIGINAL date.
SELECT n,
       (DATE '2025-01-31' + n * INTERVAL '1 month')::date AS bill_date
FROM generate_series(0, 4) AS n;                                     -- Jan 31, Feb 28, Mar 31, Apr 30, May 31

-- First and last day of the month of each order.
SELECT order_id, order_date,
       DATE_TRUNC('month', order_date)::date                                        AS month_start,
       (DATE_TRUNC('month', order_date) + INTERVAL '1 month - 1 day')::date         AS month_end
FROM orders
ORDER BY order_id
LIMIT 5;

-- ---------------------------------------------------------------
-- Differences and ages
-- ---------------------------------------------------------------
SELECT first_name, hire_date,
       CURRENT_DATE - hire_date                         AS days_employed,
       AGE(CURRENT_DATE, hire_date)                     AS tenure,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date))  AS full_years
FROM employees
ORDER BY hire_date
LIMIT 5;

SELECT EXTRACT(EPOCH FROM TIMESTAMP '2025-01-02 06:00' - TIMESTAMP '2025-01-01 00:00') / 3600 AS hours;  -- 30

-- ---------------------------------------------------------------
-- Weeks: ISO year vs calendar year
-- ---------------------------------------------------------------
SELECT d,
       EXTRACT(ISODOW FROM d)   AS iso_dow,        -- 1 = Monday
       EXTRACT(WEEK FROM d)     AS iso_week,
       TO_CHAR(d, 'YYYY-IW')    AS wrong_label,
       TO_CHAR(d, 'IYYY-IW')    AS right_label,
       DATE_TRUNC('week', d)::date AS week_start
FROM (VALUES (DATE '2025-12-28'), (DATE '2025-12-29'), (DATE '2026-01-04'), (DATE '2026-01-05')) AS t(d);

-- Working days (Mon–Fri) in March 2025.
SELECT COUNT(*) AS working_days
FROM generate_series(DATE '2025-03-01', DATE '2025-03-31', INTERVAL '1 day') AS d
WHERE EXTRACT(ISODOW FROM d) < 6;                                    -- 21

-- ---------------------------------------------------------------
-- Grouping by local day
-- ---------------------------------------------------------------
CREATE TEMP TABLE events (event_id INT, created_at TIMESTAMPTZ);
INSERT INTO events VALUES
    (1, '2025-06-01 17:00+00'),     -- 22:30 on 1 June in India
    (2, '2025-06-01 19:00+00'),     -- 00:30 on 2 June in India
    (3, '2025-06-02 08:00+00');

SELECT (created_at AT TIME ZONE 'UTC')::date          AS utc_day,   COUNT(*) FROM events GROUP BY 1 ORDER BY 1;
SELECT (created_at AT TIME ZONE 'Asia/Kolkata')::date AS india_day, COUNT(*) FROM events GROUP BY 1 ORDER BY 1;

-- ---------------------------------------------------------------
-- Filling gaps: customer 1's revenue for every month of 2025, including empty ones
-- ---------------------------------------------------------------
-- A plain GROUP BY would return only the 4 months with orders.
WITH months AS (
    SELECT generate_series(DATE '2025-01-01', DATE '2025-12-01', INTERVAL '1 month')::date AS month
)
SELECT m.month,
       COUNT(DISTINCT o.order_id)                     AS orders,
       COALESCE(SUM(oi.quantity * oi.unit_price), 0)  AS revenue
FROM months m
LEFT JOIN orders o       ON o.order_date >= m.month AND o.order_date < m.month + INTERVAL '1 month'
                        AND o.customer_id = 1               -- filter in ON, not WHERE, or the empty months vanish
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY m.month
ORDER BY m.month;                                                    -- 12 rows, 8 of them 0

-- Days in Q1 2025 with no orders at all.
SELECT d::date AS quiet_day
FROM generate_series(DATE '2025-01-01', DATE '2025-03-31', INTERVAL '1 day') AS d
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.order_date = d::date)
ORDER BY d
LIMIT 10;

-- ---------------------------------------------------------------
-- Overlapping periods
-- ---------------------------------------------------------------
CREATE TEMP TABLE bookings (booking_id INT, room INT, start_at TIMESTAMP, end_at TIMESTAMP);
INSERT INTO bookings VALUES
    (1, 101, '2025-06-01 14:00', '2025-06-03 11:00'),
    (2, 101, '2025-06-03 11:00', '2025-06-05 11:00'),    -- starts exactly when 1 ends: no overlap
    (3, 101, '2025-06-02 09:00', '2025-06-02 18:00'),    -- inside 1
    (4, 102, '2025-06-01 14:00', '2025-06-04 11:00');

SELECT a.booking_id, b.booking_id AS clashes_with
FROM bookings a
JOIN bookings b ON a.room = b.room
               AND a.booking_id < b.booking_id
               AND a.start_at < b.end_at
               AND b.start_at < a.end_at;                -- only (1, 3)

-- The same with range types.
SELECT a.booking_id, b.booking_id AS clashes_with
FROM bookings a
JOIN bookings b ON a.room = b.room AND a.booking_id < b.booking_id
               AND tsrange(a.start_at, a.end_at) && tsrange(b.start_at, b.end_at);

-- An exclusion constraint makes overlaps impossible (single resource; per-room needs btree_gist).
CREATE TEMP TABLE projector_bookings (
    booked_by TEXT,
    during    TSRANGE,
    EXCLUDE USING gist (during WITH &&)
);
INSERT INTO projector_bookings VALUES ('Asha', '[2025-06-01 09:00, 2025-06-01 10:00)');
INSERT INTO projector_bookings VALUES ('Ben',  '[2025-06-01 10:00, 2025-06-01 11:00)');   -- fine: touches, doesn't overlap
-- INSERT INTO projector_bookings VALUES ('Cara', '[2025-06-01 09:30, 2025-06-01 10:30)'); -- ERROR: conflicting key value

-- ---------------------------------------------------------------
-- NOW() is frozen for the transaction
-- ---------------------------------------------------------------
BEGIN;
SELECT NOW() AS now_1, clock_timestamp() AS clock_1;
SELECT pg_sleep(0.1);
SELECT NOW() AS now_2, clock_timestamp() AS clock_2;     -- now_2 = now_1; clock_2 has moved on
COMMIT;
