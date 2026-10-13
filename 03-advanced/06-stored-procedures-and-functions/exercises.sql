-- 06 · Exercises with solutions

-- 1. A function order_total(order_id) returning the order's value (0 if it has no items).
CREATE OR REPLACE FUNCTION order_total(p_order_id INT)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(SUM(quantity * unit_price), 0) FROM order_items WHERE order_id = p_order_id;
$$;

SELECT order_id, order_total(order_id) FROM orders ORDER BY order_id;

-- 2. A function years_of_service(emp_id, as_of DATE) returning whole years.
CREATE OR REPLACE FUNCTION years_of_service(p_emp_id INT, p_as_of DATE DEFAULT CURRENT_DATE)
RETURNS INT
LANGUAGE sql
STABLE
AS $$
    SELECT EXTRACT(YEAR FROM AGE(p_as_of, hire_date))::INT FROM employees WHERE emp_id = p_emp_id;
$$;

SELECT first_name, years_of_service(emp_id, DATE '2026-01-01') FROM employees ORDER BY 2 DESC;

-- 3. A procedure give_raise(dept_id, percent) that refuses raises above 20%.
CREATE OR REPLACE PROCEDURE give_raise(p_dept INT, p_percent NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_percent > 20 THEN
        RAISE EXCEPTION 'Raise of %%% is too large', p_percent;
    END IF;
    UPDATE employees SET salary = salary * (1 + p_percent / 100) WHERE dept_id = p_dept;
END;
$$;

CALL give_raise(3, 5);
SELECT first_name, salary FROM employees WHERE dept_id = 3;

-- 4. A procedure place_order(customer, product, qty) that creates the order and item,
--    charges the list price, reduces stock, and fails cleanly if stock is insufficient.
CREATE OR REPLACE PROCEDURE place_order(p_customer INT, p_product INT, p_qty INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_price  NUMERIC;
    v_stock  INT;
    v_order  INT;
BEGIN
    SELECT price, stock INTO v_price, v_stock FROM products WHERE product_id = p_product FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unknown product %', p_product;
    END IF;
    IF v_stock < p_qty THEN
        RAISE EXCEPTION 'Only % in stock', v_stock;
    END IF;

    SELECT COALESCE(MAX(order_id), 0) + 1 INTO v_order FROM orders;   -- a sequence is better in real life
    INSERT INTO orders VALUES (v_order, p_customer, CURRENT_DATE, 'pending');
    INSERT INTO order_items VALUES (v_order, p_product, p_qty, v_price);
    UPDATE products SET stock = stock - p_qty WHERE product_id = p_product;
END;
$$;

CALL place_order(9, 3, 2);
SELECT * FROM orders ORDER BY order_id DESC LIMIT 1;

DROP PROCEDURE place_order, give_raise;
DROP FUNCTION years_of_service, order_total;
