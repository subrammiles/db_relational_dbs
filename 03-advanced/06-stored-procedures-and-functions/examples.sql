-- 06 · Stored procedures and functions (PostgreSQL / PL/pgSQL)

-- ---------------------------------------------------------------
-- Anonymous block: run procedural code once, store nothing
-- ---------------------------------------------------------------
DO $$
DECLARE
    message VARCHAR(20) := 'Hello, World!';
BEGIN
    RAISE NOTICE '%', message;
END $$;

-- ---------------------------------------------------------------
-- 1. A plain SQL function (no procedural code needed)
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION full_name(p_first VARCHAR, p_last VARCHAR)
RETURNS VARCHAR
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT p_first || ' ' || p_last;
$$;

SELECT full_name(first_name, last_name) FROM employees LIMIT 3;

-- ---------------------------------------------------------------
-- 2. PL/pgSQL function with a variable, IF and an error
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION annual_salary(p_emp_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_salary employees.salary%TYPE;      -- same type as the column
BEGIN
    SELECT salary INTO v_salary FROM employees WHERE emp_id = p_emp_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee % not found', p_emp_id;
    END IF;
    RETURN v_salary * 12;
END;
$$;

SELECT annual_salary(3);                          -- used like any expression
SELECT first_name, annual_salary(emp_id) FROM employees WHERE dept_id = 4;

-- ---------------------------------------------------------------
-- 3. Function returning a table: usable in FROM
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION customer_orders(p_customer_id INT)
RETURNS TABLE (order_id INT, order_date DATE, status VARCHAR, total NUMERIC)
LANGUAGE sql
STABLE
AS $$
    SELECT o.order_id, o.order_date, o.status, SUM(oi.quantity * oi.unit_price)
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.customer_id = p_customer_id
    GROUP BY o.order_id, o.order_date, o.status
    ORDER BY o.order_date;
$$;

SELECT * FROM customer_orders(1);
SELECT c.name, t.* FROM customers c CROSS JOIN LATERAL customer_orders(c.customer_id) t WHERE c.country = 'UK';

-- ---------------------------------------------------------------
-- 4. Loops and CASE: classify every product and count the classes
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION stock_report()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    r        RECORD;
    n_out    INT := 0;
    n_low    INT := 0;
    n_ok     INT := 0;
BEGIN
    FOR r IN SELECT product_name, stock FROM products LOOP
        CASE
            WHEN r.stock = 0  THEN n_out := n_out + 1;
            WHEN r.stock < 30 THEN n_low := n_low + 1;
            ELSE                   n_ok  := n_ok + 1;
        END CASE;
    END LOOP;
    RETURN format('out=%s low=%s ok=%s', n_out, n_low, n_ok);
END;
$$;

SELECT stock_report();

-- ---------------------------------------------------------------
-- 5. A procedure: the bank transfer with validation
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE transfer(p_from INT, p_to INT, p_amount NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
    v_balance NUMERIC;
BEGIN
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive';
    END IF;

    -- Lock both rows in a fixed order to avoid deadlocks
    PERFORM 1 FROM accounts WHERE account_id IN (p_from, p_to) ORDER BY account_id FOR UPDATE;

    SELECT balance INTO v_balance FROM accounts WHERE account_id = p_from;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Source account % not found', p_from;
    END IF;
    IF v_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds: balance %, requested %', v_balance, p_amount;
    END IF;

    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_to;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Target account % not found', p_to;
    END IF;
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_from;
END;
$$;

CALL transfer(1, 3, 1500);
SELECT * FROM accounts ORDER BY account_id;     -- Alice 3500, Carol 1500

-- Errors roll back the whole CALL
DO $$
BEGIN
    CALL transfer(2, 99, 100);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Failed: %', SQLERRM;
END $$;

-- ---------------------------------------------------------------
-- 6. OUT / INOUT parameters
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE dept_stats(IN p_dept INT, OUT p_count INT, OUT p_avg NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*), ROUND(AVG(salary), 0) INTO p_count, p_avg
    FROM employees WHERE dept_id = p_dept;
END;
$$;

CALL dept_stats(1, NULL, NULL);                  -- returns p_count, p_avg

-- ---------------------------------------------------------------
-- 7. Dynamic SQL done safely: format('%I') for identifiers, USING for values
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION count_rows(p_table TEXT, p_column TEXT, p_min INT)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    n BIGINT;
BEGIN
    -- %I quotes identifiers safely; $1 is a bind parameter filled by USING
    EXECUTE format('SELECT COUNT(*) FROM %I WHERE %I >= $1', p_table, p_column)
    INTO n
    USING p_min;
    RETURN n;
END;
$$;

SELECT count_rows('orders', 'order_id', 10);         -- 9
SELECT count_rows('customers', 'customer_id', 5);    -- 6

-- ---------------------------------------------------------------
-- 8. A procedure that commits in a loop (batch processing)
-- ---------------------------------------------------------------
CREATE OR REPLACE PROCEDURE archive_in_batches()
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT order_id FROM orders WHERE status = 'cancelled' ORDER BY order_id LOOP
        RAISE NOTICE 'would archive order %', r.order_id;
        COMMIT;                                  -- allowed in procedures, not in functions
    END LOOP;
END;
$$;

CALL archive_in_batches();

-- List your functions and procedures
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
ORDER BY routine_type, routine_name;

-- Clean up
DROP PROCEDURE archive_in_batches, dept_stats, transfer;
DROP FUNCTION count_rows, stock_report, customer_orders, annual_salary, full_name;
