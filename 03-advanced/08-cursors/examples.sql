-- 08 · Cursors (PostgreSQL / PL/pgSQL)

-- ---------------------------------------------------------------
-- 1. Explicit cursor: DECLARE → OPEN → FETCH loop → CLOSE
-- ---------------------------------------------------------------
DO $$
DECLARE
    c_emps CURSOR FOR
        SELECT first_name, salary FROM employees WHERE dept_id = 2 ORDER BY salary DESC;
    r RECORD;
    n INT := 0;
BEGIN
    OPEN c_emps;
    LOOP
        FETCH c_emps INTO r;
        EXIT WHEN NOT FOUND;                         -- no more rows
        n := n + 1;
        RAISE NOTICE '%: % earns %', n, r.first_name, r.salary;
    END LOOP;
    CLOSE c_emps;
END $$;

-- ---------------------------------------------------------------
-- 2. FOR loop over a query: opens, fetches and closes automatically
-- ---------------------------------------------------------------
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT d.dept_name, COUNT(e.emp_id) AS n
             FROM departments d LEFT JOIN employees e ON e.dept_id = d.dept_id
             GROUP BY d.dept_name ORDER BY d.dept_name
    LOOP
        RAISE NOTICE '% has % employee(s)', r.dept_name, r.n;
    END LOOP;
END $$;

-- ---------------------------------------------------------------
-- 3. Parameterised cursor
-- ---------------------------------------------------------------
DO $$
DECLARE
    c_by_country CURSOR (p_country VARCHAR) FOR
        SELECT name FROM customers WHERE country = p_country ORDER BY name;
    r RECORD;
BEGIN
    FOR r IN c_by_country('India') LOOP
        RAISE NOTICE 'Indian customer: %', r.name;
    END LOOP;
END $$;

-- ---------------------------------------------------------------
-- 4. Updating the row under the cursor (WHERE CURRENT OF)
-- ---------------------------------------------------------------
BEGIN;
DO $$
DECLARE
    c_low CURSOR FOR SELECT emp_id, salary FROM employees WHERE salary < 70000 FOR UPDATE;
    r RECORD;
BEGIN
    FOR r IN c_low LOOP
        UPDATE employees SET salary = salary + 5000 WHERE CURRENT OF c_low;
    END LOOP;
END $$;
SELECT first_name, salary FROM employees WHERE salary < 75000 ORDER BY salary;
ROLLBACK;

-- The set-based way does the same in one statement, and is much faster on big tables:
--   UPDATE employees SET salary = salary + 5000 WHERE salary < 70000;

-- ---------------------------------------------------------------
-- 5. Returning a cursor from a function (refcursor) for the caller to fetch
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION open_orders_cursor(p_status VARCHAR)
RETURNS refcursor
LANGUAGE plpgsql
AS $$
DECLARE
    c refcursor := 'orders_cur';          -- name it so the caller can FETCH from it
BEGIN
    OPEN c FOR SELECT order_id, customer_id, order_date FROM orders WHERE status = p_status ORDER BY order_id;
    RETURN c;
END;
$$;

BEGIN;                                    -- cursors live until the end of the transaction
SELECT open_orders_cursor('delivered');
FETCH 3 FROM orders_cur;                  -- first 3 rows
FETCH 3 FROM orders_cur;                  -- next 3
CLOSE orders_cur;
COMMIT;

-- ---------------------------------------------------------------
-- 6. Plain SQL cursor: stream a large result in chunks
-- ---------------------------------------------------------------
BEGIN;
DECLARE big_cur CURSOR FOR SELECT * FROM order_items ORDER BY order_id;
FETCH 10 FROM big_cur;
FETCH 10 FROM big_cur;
MOVE ABSOLUTE 0 IN big_cur;               -- rewind (needs SCROLL for backwards moves in general)
CLOSE big_cur;
COMMIT;

DROP FUNCTION open_orders_cursor;
