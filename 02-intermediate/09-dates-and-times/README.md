# 09 · Dates, times and time zones

[Lesson 07](../07-built-in-functions/) lists the date functions. This lesson covers the parts that cause real bugs: choosing the right type, time zones, daylight saving time, date ranges, month arithmetic and filling gaps in time series. Interviewers like it because almost everyone has shipped one of these bugs.

## The types

| Meaning | PostgreSQL | MySQL | Oracle | SQL Server | SQLite |
|---|---|---|---|---|---|
| Calendar date | `DATE` | `DATE` | `DATE` (**also holds a time!**) | `DATE` | text `'2025-01-31'` |
| Time of day | `TIME` | `TIME` | none (use `DATE` / `INTERVAL DAY TO SECOND`) | `TIME` | text |
| Date + time, no zone ("wall clock") | `TIMESTAMP` | `DATETIME` | `TIMESTAMP` | `DATETIME2` | text / number |
| An exact instant | `TIMESTAMPTZ` | `TIMESTAMP` (stored as UTC, 1970–2038 only) | `TIMESTAMP WITH TIME ZONE` / `WITH LOCAL TIME ZONE` | `DATETIMEOFFSET` | Unix epoch number |
| Duration | `INTERVAL` | none (use numbers) | `INTERVAL YEAR TO MONTH`, `INTERVAL DAY TO SECOND` | none (use numbers) | none |

Things to know about each database:
- **PostgreSQL `TIMESTAMPTZ` does not store a time zone.** It converts the input to UTC, stores that, and shows it in the session's `TimeZone`. The name is misleading. It means "timestamp that knows about time zones".
- **Oracle `DATE` holds a time down to the second.** `WHERE order_date = DATE '2025-01-10'` misses rows saved at 14:30. Use `TRUNC(order_date)` or a range.
- **SQL Server `DATETIME` (the old type) rounds to 1/300 of a second.** `'2025-01-31 23:59:59.999'` becomes the next midnight. Use `DATETIME2` in new code.
- **MySQL `TIMESTAMP` ends in 2038.** It's a 32-bit Unix time. `DATETIME` has no zone but no 2038 limit.

## Which type to use

| You're storing | Use | Why |
|---|---|---|
| When something happened (order placed, login, log line) | `TIMESTAMPTZ` / UTC | It's an exact instant. Convert to local time only when displaying it. |
| A birthday, a due date, a holiday | `DATE` | No time and no zone. `2025-12-25` is Christmas everywhere. |
| A future local event ("dentist at 09:00 in Paris, next June") | `TIMESTAMP` **+ a zone name column** | Governments change DST rules. Store what the person asked for and convert later. |
| Opening hours ("09:00–17:00 every day") | `TIME` (+ the shop's zone) | It isn't tied to a date. |
| How long something took | `INTERVAL` or a number of seconds | Don't put durations in a `TIME` column. `TIME` stops at 24h. |

## Time zones in PostgreSQL

```sql
SHOW TimeZone;                         -- the session's zone; it controls input and display
SET TIME ZONE 'Asia/Kolkata';          -- for this session only

SELECT TIMESTAMPTZ '2025-06-01 12:00:00+00';   -- shown as 2025-06-01 17:30:00+05:30
```

`AT TIME ZONE` converts **in both directions**, depending on the input type:

```sql
-- instant  → wall clock in Tokyo   (TIMESTAMPTZ in, TIMESTAMP out)
SELECT TIMESTAMPTZ '2025-06-01 12:00:00+00' AT TIME ZONE 'Asia/Tokyo';     -- 2025-06-01 21:00:00

-- wall clock in Tokyo → instant    (TIMESTAMP in, TIMESTAMPTZ out)
SELECT TIMESTAMP '2025-06-01 21:00:00' AT TIME ZONE 'Asia/Tokyo';          -- 2025-06-01 12:00:00+00
```

Common mistakes:
- **Use zone names such as `'Europe/London'`, not fixed offsets such as `'+01'`.** An offset can't know about daylight saving time, and London is +00 in winter.
- **POSIX offsets have the opposite sign.** In `SET TIME ZONE 'UTC+5'` and `AT TIME ZONE 'UTC+5'`, the zone `UTC+5` means 5 hours *west* of Greenwich (UTC−5). ISO offsets inside literals (`'...10:00+05'`) use the normal sign. Using zone names avoids the problem.
- **Don't rely on the server's zone.** Set the zone explicitly in the session or connection string, or convert with `AT TIME ZONE`.

Other databases:

| Task | MySQL | Oracle | SQL Server |
|---|---|---|---|
| Current UTC time | `UTC_TIMESTAMP()` | `SYS_EXTRACT_UTC(SYSTIMESTAMP)` | `SYSUTCDATETIME()` |
| UTC → local | `CONVERT_TZ(dt, 'UTC', 'Asia/Kolkata')` (needs the zone tables loaded) | `FROM_TZ(ts, 'UTC') AT TIME ZONE 'Asia/Kolkata'` | `dt AT TIME ZONE 'UTC' AT TIME ZONE 'India Standard Time'` (Windows zone names) |
| Session zone | `SET time_zone = '+00:00'` | `ALTER SESSION SET TIME_ZONE = 'UTC'` | none (follows the server OS) |

## Daylight saving time

In 2025, New York moved its clocks forward on 9 March, so that day had only 23 hours. In PostgreSQL, `TIMESTAMPTZ` arithmetic follows the session's zone:

```sql
SET TIME ZONE 'America/New_York';
SELECT TIMESTAMPTZ '2025-03-08 12:00' + INTERVAL '1 day';     -- 2025-03-09 12:00-04  (same clock time)
SELECT TIMESTAMPTZ '2025-03-08 12:00' + INTERVAL '24 hours';  -- 2025-03-09 13:00-04  (exactly 24h later)
```

Use `'1 day'` for "same time tomorrow" and `'24 hours'` for "a fixed amount of time later". Some local times never happen (02:30 on the day clocks go forward) and some happen twice (01:30 on the day they go back). Storing instants in UTC avoids both problems.

## Querying date ranges: use half-open intervals

```sql
-- ❌ misses every order after midnight on 31 January if order_ts has a time part
WHERE order_ts BETWEEN '2025-01-01' AND '2025-01-31'

-- ❌ index on order_ts can't be used (non-sargable)
WHERE order_ts::date = '2025-01-15'
WHERE EXTRACT(YEAR FROM order_ts) = 2025

-- ✅ start inclusive, end exclusive: works for DATE and TIMESTAMP, uses the index, no 23:59:59.999 guessing
WHERE order_ts >= '2025-01-01' AND order_ts < '2025-02-01'
```

Half-open ranges `[start, end)` also join up cleanly: January ends exactly where February starts, so nothing is counted twice or missed.

## Month arithmetic is not reversible

```sql
SELECT DATE '2025-01-31' + INTERVAL '1 month';                         -- 2025-02-28 (clamped to the month's end)
SELECT DATE '2025-01-31' + INTERVAL '1 month' - INTERVAL '1 month';    -- 2025-01-28, not 01-31
SELECT DATE '2024-02-29' + INTERVAL '1 year';                          -- 2025-02-28
```

For "the same day each month", always add `n months` to the **original** date. Don't add one month at a time to the previous result, or Jan 31 → Feb 28 → Mar 28 drifts. In PostgreSQL, `DATE + INTERVAL` returns a `TIMESTAMP`. Cast it back with `::date` if you need a date.

## Differences and ages

```sql
SELECT DATE '2025-03-01' - DATE '2025-01-01';                       -- 59 (an integer number of days)
SELECT AGE(DATE '2025-03-15', DATE '1990-07-20');                   -- 34 years 7 mons 23 days
SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, DATE '1990-07-20'));     -- age in whole years
SELECT EXTRACT(EPOCH FROM TIMESTAMP '2025-01-02 06:00' - TIMESTAMP '2025-01-01 00:00') / 3600;   -- 30 hours
```

`DATEDIFF(month, '2025-01-31', '2025-02-01')` in SQL Server returns **1**. It counts month *boundaries crossed*, not complete months. MySQL's `TIMESTAMPDIFF(MONTH, ...)` counts complete months (0 here).

## Weeks

| What | PostgreSQL |
|---|---|
| ISO day of week (Mon = 1 … Sun = 7) | `EXTRACT(ISODOW FROM d)` |
| ISO week number | `EXTRACT(WEEK FROM d)` |
| Start of the week (Monday) | `DATE_TRUNC('week', d)` |
| Year-week label | `TO_CHAR(d, 'IYYY-IW')`, **not** `'YYYY-IW'` |

`2025-12-29` falls in ISO week 1 **of 2026**. `TO_CHAR(d, 'YYYY-IW')` labels it `2025-01`, so that week ends up in the same group as the first week of January 2025.

## Grouping by local day

"Orders per day" depends on *whose* day you mean. Convert first, then truncate:

```sql
SELECT DATE_TRUNC('day', created_at AT TIME ZONE 'Asia/Kolkata')::date AS local_day, COUNT(*)
FROM events
GROUP BY 1;

SELECT DATE_TRUNC('day', created_at, 'Asia/Kolkata') ...   -- PostgreSQL 12+: same idea, returns TIMESTAMPTZ
```

## Filling gaps in a time series

`GROUP BY month` returns no row at all for a month with no sales, so charts and averages come out wrong. Generate the calendar and `LEFT JOIN` the data to it:

```sql
WITH months AS (
    SELECT generate_series(DATE '2025-01-01', DATE '2025-12-01', INTERVAL '1 month')::date AS month
)
SELECT m.month, COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS revenue
FROM months m
LEFT JOIN orders o       ON o.order_date >= m.month AND o.order_date < m.month + INTERVAL '1 month'
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY m.month
ORDER BY m.month;
```

Other databases: a recursive CTE (MySQL, SQL Server, SQLite), `CONNECT BY LEVEL <= n` (Oracle), or a permanent **calendar / date dimension table** (see [lesson 16](../../03-advanced/16-data-warehousing-and-scd/)), which can also hold holidays and fiscal periods.

## Overlapping periods

Two periods `[a_start, a_end)` and `[b_start, b_end)` overlap when **each starts before the other ends**:

```sql
WHERE a.start_at < b.end_at AND b.start_at < a.end_at
```

Most people first try listing cases ("a starts inside b, or a ends inside b, or…") and miss the case where one period contains the other. The two-comparison test covers all cases.

PostgreSQL also has range types, which make overlap a single operator. An **exclusion constraint** can then forbid overlapping rows outright:

```sql
CREATE TABLE room_bookings (
    room_id INT,
    during  TSTZRANGE,               -- '[2025-06-01 14:00, 2025-06-03 11:00)'
    EXCLUDE USING gist (room_id WITH =, during WITH &&)    -- needs: CREATE EXTENSION btree_gist;
);
```

## "Now" isn't one thing

| PostgreSQL | Value |
|---|---|
| `NOW()`, `CURRENT_TIMESTAMP`, `transaction_timestamp()` | Start of the **transaction**: the same for every row and statement in it |
| `statement_timestamp()` | Start of the current statement |
| `clock_timestamp()` | The real time, changes even within one statement |
| `CURRENT_DATE` | Today **in the session's time zone** |

Because `NOW()` doesn't change inside a transaction, every row inserted together gets the same timestamp. That's usually what you want. Use `clock_timestamp()` to time things.

## Interview questions

1. **`TIMESTAMP` vs `TIMESTAMPTZ` in PostgreSQL?** `TIMESTAMP` is a wall-clock reading with no zone. `TIMESTAMPTZ` is an exact instant: it's stored as UTC and displayed in the session's zone. Neither stores the zone name.
2. **How would you store event times for a global app?** As UTC instants (`TIMESTAMPTZ`, or `DATETIMEOFFSET`/UTC `DATETIME2`). Store each user's zone name separately, and convert only for display and for "per local day" reports.
3. **Why is `BETWEEN '2025-01-01' AND '2025-01-31'` wrong for timestamps?** The upper bound means midnight at the *start* of 31 January, so that whole day is missed. Use `>= '2025-01-01' AND < '2025-02-01'`.
4. **What is 31 January plus one month?** 28 February (29 in a leap year) in PostgreSQL, MySQL, Oracle and SQL Server. Subtracting a month afterwards gives 28 January, so month arithmetic can't be undone.
5. **Why does a daily report show a day with 23 or 25 hours?** Daylight saving time. Group by local date with `AT TIME ZONE`, and don't assume every day has 24 hours.
6. **How do you show months with zero sales?** Generate the months (`generate_series`, a recursive CTE or a calendar table) and `LEFT JOIN` the facts, using `COALESCE(SUM(...), 0)`.
7. **How do you check if two bookings overlap?** `a.start < b.end AND b.start < a.end`. In PostgreSQL, use `tstzrange && tstzrange`, and an exclusion constraint to prevent overlaps.
8. **Within one transaction, does `NOW()` change?** No. It's the transaction's start time. `clock_timestamp()` gives the real time.
9. **Oracle trap with `DATE`?** It includes a time of day, so an equality check against a date literal misses rows with a time part.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql)

Next: [03-advanced · Common table expressions](../../03-advanced/01-common-table-expressions/)
