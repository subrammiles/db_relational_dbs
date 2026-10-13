-- 08 · Exercises with solutions

-- 1. Using a cursor FOR loop, print every customer's name with their number of orders.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT c.name, COUNT(o.order_id) AS n
        FROM customers c LEFT JOIN orders o ON o.customer_id = c.customer_id
        GROUP BY c.customer_id, c.name
        ORDER BY c.name
    LOOP
        RAISE NOTICE '% has % order(s)', r.name, r.n;
    END LOOP;
END $$;

-- 2. With an explicit cursor (OPEN / FETCH / CLOSE), find the first product whose
--    cumulative stock, in product_id order, exceeds 500. Stop fetching as soon as you find it.
DO $$
DECLARE
    c CURSOR FOR SELECT product_id, product_name, stock FROM products ORDER BY product_id;
    r RECORD;
    running INT := 0;
BEGIN
    OPEN c;
    LOOP
        FETCH c INTO r;
        EXIT WHEN NOT FOUND;
        running := running + r.stock;
        IF running > 500 THEN
            RAISE NOTICE 'Threshold passed at % (running stock %)', r.product_name, running;
            EXIT;
        END IF;
    END LOOP;
    CLOSE c;
END $$;

-- 3. Rewrite question 2 without a cursor (set-based, with a window function).
SELECT product_id, product_name, running
FROM (
    SELECT product_id, product_name, SUM(stock) OVER (ORDER BY product_id) AS running
    FROM products
) t
WHERE running > 500
ORDER BY product_id
LIMIT 1;

-- 4. A function that returns a refcursor over the employees of a given department;
--    fetch the first 2 rows from it.
CREATE OR REPLACE FUNCTION dept_employees(p_dept INT)
RETURNS refcursor
LANGUAGE plpgsql
AS $$
DECLARE
    c refcursor := 'dept_cur';
BEGIN
    OPEN c FOR SELECT first_name, salary FROM employees WHERE dept_id = p_dept ORDER BY salary DESC;
    RETURN c;
END;
$$;

BEGIN;
SELECT dept_employees(1);
FETCH 2 FROM dept_cur;
CLOSE dept_cur;
COMMIT;

DROP FUNCTION dept_employees;
