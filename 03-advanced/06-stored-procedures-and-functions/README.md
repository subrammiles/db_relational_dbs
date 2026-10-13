# 06 · Stored procedures and functions

Code stored **inside the database** and run there, close to the data.

| | Function | Procedure |
|---|---|---|
| Returns | A value or a table (always) | Nothing, or values through `OUT` / `INOUT` parameters |
| Called with | `SELECT my_func(1);` or inside any query | `CALL my_proc(1);` (Oracle: `EXEC`, SQL Server: `EXEC`) |
| Use in `SELECT`/`WHERE` | ✔ | ✘ |
| Transaction control (`COMMIT` inside) | ✘ | ✔ (PostgreSQL 11+, Oracle, MySQL, SQL Server) |
| Typical use | Calculations, reusable expressions, table-returning queries | Multi-step business operations, batch jobs |

## Procedural languages

| Database | Language |
|---|---|
| PostgreSQL | PL/pgSQL (plus SQL, PL/Python, PL/Perl...) |
| Oracle | **PL/SQL** |
| MySQL / MariaDB | SQL/PSM-style compound statements |
| SQL Server | T-SQL |
| SQLite | None (functions are registered from the host language) |

They all add: variables, `IF`/`CASE`, loops, exception handling, cursors and dynamic SQL on top of SQL.

## PostgreSQL syntax

```sql
CREATE OR REPLACE FUNCTION annual_salary(p_emp_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_salary NUMERIC;
BEGIN
    SELECT salary INTO v_salary FROM employees WHERE emp_id = p_emp_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Employee % not found', p_emp_id;
    END IF;
    RETURN v_salary * 12;
END;
$$;

CREATE OR REPLACE PROCEDURE transfer(p_from INT, p_to INT, p_amount NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_from;
    UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_to;
END;
$$;

CALL transfer(1, 2, 500);
```

`$$ ... $$` is dollar quoting: the body is a string without needing to escape single quotes.

### Function attributes (PostgreSQL)

- `IMMUTABLE`: same inputs always give same output, no DB access (`lower`, maths). Required for expression indexes.
- `STABLE`: doesn't modify the DB; same result within one statement.
- `VOLATILE` (default): may change anything (`random()`, `now()`-dependent, writes).
- `SECURITY DEFINER`: runs with the owner's privileges (like setuid). Set `search_path` explicitly when you use it.

## MySQL needs DELIMITER

The `;` inside the body would end the `CREATE` statement in the mysql client, so temporarily change the delimiter:

```sql
DELIMITER //
CREATE PROCEDURE GetEmployees()
BEGIN
    SELECT * FROM employees;
END //
DELIMITER ;

CALL GetEmployees();
```

GUI tools and drivers usually don't need `DELIMITER`.

## Pros and cons

**Pros:** fewer network round trips; logic and data rules in one place shared by every app; can grant `EXECUTE` without granting table access; precompiled plans (SQL Server/Oracle).

**Cons:** harder to version, test, debug and review than app code; vendor lock-in; scaling logic in the database means scaling the database (the most expensive tier); business logic gets split between app and DB.

Common middle ground: keep integrity rules in constraints, data-heavy batch operations in procedures, and business workflows in the application.

## Interview questions

1. **Stored procedure vs function?** Function returns a value and can be used in queries; procedure is called with `CALL`, returns via OUT params, and can manage transactions.
2. **Advantages of stored procedures?** Performance (fewer round trips), security (grant EXECUTE only), reuse, central rules.
3. **Disadvantages?** Portability, testing/versioning, debugging, scaling the DB tier.
4. **What are IN, OUT and INOUT parameters?** Input only; output only (set by the procedure); both.
5. **Can a function modify data?** PostgreSQL: yes (if VOLATILE). Oracle: not when called from a SELECT. SQL Server: no (user-defined functions are read-only).
6. **How do you handle errors in PL/SQL / PL/pgSQL?** `EXCEPTION WHEN ... THEN` blocks; raise your own with `RAISE EXCEPTION` (PG) / `RAISE_APPLICATION_ERROR` (Oracle) / `SIGNAL` (MySQL).
7. **What is dynamic SQL and its risk?** Building SQL text at runtime (`EXECUTE`, `EXECUTE IMMEDIATE`); SQL injection if you concatenate input. Use bind variables (`USING`) and `format('%I', ...)` for identifiers.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql)
- [mysql.sql](mysql.sql): procedures with IN/OUT params, error handling with `SIGNAL`
- [oracle.sql](oracle.sql): PL/SQL basics (anonymous blocks, IF, procedures, functions, packages)

Next: [07 · Triggers](../07-triggers/)
