# 03 · INSERT

## Syntax

```sql
-- One row; always list the columns
INSERT INTO table_name (col1, col2) VALUES (val1, val2);

-- Several rows in one statement (PostgreSQL, MySQL, SQLite, SQL Server, Oracle 23c)
INSERT INTO table_name (col1, col2) VALUES
    (val1, val2),
    (val3, val4);

-- Rows produced by a query
INSERT INTO target (col1, col2)
SELECT a, b FROM source WHERE ...;
```

- Columns you leave out get their `DEFAULT`, or `NULL` if there is none.
- An identity / auto-increment column is filled automatically. Don't list it.
- Strings and dates go in **single** quotes. Double quotes are for identifiers (`"Column Name"`).
- To put a quote inside a string, double it: `'O''Brien'`.

## Getting the generated id back

| Database | How |
|---|---|
| PostgreSQL | `INSERT ... RETURNING user_id;` |
| MySQL | `SELECT LAST_INSERT_ID();` right after the insert |
| Oracle | `INSERT ... RETURNING id INTO :v_id;` (PL/SQL) |
| SQL Server | `OUTPUT inserted.id` or `SCOPE_IDENTITY()` |
| SQLite | `last_insert_rowid()` or `RETURNING` (3.35+) |

## Multi-row insert in older Oracle

```sql
INSERT ALL
    INTO employee (emp_id, full_name) VALUES (21, 'Samantha')
    INTO employee (emp_id, full_name) VALUES (22, 'Trump')
SELECT * FROM dual;
```

`INSERT ALL` can also write to **different** tables from one statement, and `INSERT FIRST ... WHEN condition THEN INTO ...` sends each row to the first matching table.

## Insert or update if it exists ("upsert")

Covered in [03-advanced/11-upsert-and-merge](../../03-advanced/11-upsert-and-merge/).

## Common mistakes

- Leaving the column list out: `INSERT INTO t VALUES (...)` breaks as soon as someone adds a column.
- Inserting a child row before its parent: the foreign key rejects it.
- Inserting in a loop one row at a time from application code; multi-row inserts or `COPY` (PostgreSQL) / `LOAD DATA` (MySQL) are much faster for bulk loads.
- Building the `VALUES` string by concatenating user input → SQL injection. Use parameters.

## Interview questions

1. **How do you copy rows from one table to another?** `INSERT INTO target (cols) SELECT cols FROM source WHERE ...`.
2. **How do you insert multiple rows efficiently?** One multi-row `INSERT`, a batch of parameterised inserts in one transaction, or a bulk loader (`COPY`, `LOAD DATA INFILE`, SQL*Loader).
3. **What happens to columns you omit?** They get their default value, or NULL; if they're `NOT NULL` without a default, the insert fails.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [mysql.sql](mysql.sql) · [oracle.sql](oracle.sql)

Next: [04 · SELECT and WHERE](../04-select-and-where/)
