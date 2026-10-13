# 05 · Filtering operators: AND, OR, NOT, IN, BETWEEN, LIKE, IS NULL

## Logical operators

```sql
WHERE dept_id = 1 AND salary > 100000
WHERE city = 'Mumbai' OR city = 'Delhi'
WHERE NOT (status = 'cancelled')
```

**Precedence: `NOT` > `AND` > `OR`.** Use parentheses whenever you mix `AND` and `OR`:

```sql
-- Wrong: means  dept 1  OR  (dept 2 AND salary > 100000)
WHERE dept_id = 1 OR dept_id = 2 AND salary > 100000
-- Right
WHERE (dept_id = 1 OR dept_id = 2) AND salary > 100000
```

## IN / NOT IN

```sql
WHERE country IN ('India', 'UK', 'Spain')        -- shorter than three ORs
WHERE dept_id NOT IN (1, 2)
WHERE customer_id IN (SELECT customer_id FROM orders)   -- subquery (lesson 02-05)
```

⚠️ **`NOT IN` with a NULL in the list returns no rows.** `x NOT IN (1, NULL)` means `x <> 1 AND x <> NULL`, and `x <> NULL` is UNKNOWN. Prefer `NOT EXISTS` with subqueries.

## BETWEEN

```sql
WHERE salary BETWEEN 60000 AND 100000            -- inclusive on both ends
WHERE order_date BETWEEN '2025-01-01' AND '2025-03-31'
```

With timestamps, `BETWEEN '2025-01-01' AND '2025-03-31'` misses everything after midnight on the 31st. Use a half-open range: `>= '2025-01-01' AND < '2025-04-01'`.

## LIKE and wildcards

| Wildcard | Matches | Example | Matches |
|---|---|---|---|
| `%` | Any number of characters (including none) | `'A%'` | Asha, Arjun, Anita |
| `_` | Exactly one character | `'_a%'` | Karan, Rahul, Farhan |

```sql
WHERE first_name LIKE 'A%'        -- starts with A
WHERE first_name LIKE '%a'        -- ends with a
WHERE email LIKE '%mehta%'        -- contains mehta
WHERE product_name LIKE '%\%%'    -- contains a literal % (escape with \, or use ESCAPE '!')
```

Case sensitivity: `LIKE` is case-sensitive in PostgreSQL and Oracle, case-insensitive in MySQL (default collation) and SQLite (for ASCII). PostgreSQL has `ILIKE` for case-insensitive matching; elsewhere use `LOWER(col) LIKE 'a%'`.

A leading wildcard (`'%abc'`) can't use a normal B-tree index, so it scans the whole table.

### Regular expressions

| Database | Syntax |
|---|---|
| PostgreSQL | `col ~ '^A.*a$'`, `~*` for case-insensitive |
| MySQL 8 | `col REGEXP '^A.*a$'` |
| Oracle | `REGEXP_LIKE(col, '^A.*a$', 'i')` |

## IS NULL / IS NOT NULL

```sql
WHERE dept_id IS NULL
WHERE email IS NOT NULL
```

## Three-valued logic

SQL conditions can be TRUE, FALSE or **UNKNOWN** (whenever NULL is involved).

| A | B | A AND B | A OR B |
|---|---|---|---|
| TRUE | UNKNOWN | UNKNOWN | TRUE |
| FALSE | UNKNOWN | FALSE | UNKNOWN |
| UNKNOWN | UNKNOWN | UNKNOWN | UNKNOWN |

`NOT UNKNOWN` is still UNKNOWN. `WHERE` keeps only TRUE.

## Interview questions

1. **What's the difference between `IN` and `EXISTS`?** `IN` compares a value against a list/subquery result; `EXISTS` checks whether a correlated subquery returns any row. Modern optimisers often produce the same plan, but `NOT EXISTS` is NULL-safe while `NOT IN` is not.
2. **Is BETWEEN inclusive?** Yes, both ends.
3. **How do you find names containing an underscore?** Escape it: `LIKE '%\_%'` (PostgreSQL/MySQL default escape) or `LIKE '%!_%' ESCAPE '!'`.
4. **How do you do a case-insensitive search?** `ILIKE` (PostgreSQL), `LOWER(col) = LOWER(:value)` everywhere, a case-insensitive collation (MySQL default), or `NLS_COMP=LINGUISTIC` in Oracle (see [oracle-case-insensitive-search.sql](oracle-case-insensitive-search.sql)). Index the expression you search on.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [mysql.sql](mysql.sql) · [oracle.sql](oracle.sql) · [oracle-case-insensitive-search.sql](oracle-case-insensitive-search.sql)

Next: [06 · Sorting and pagination](../06-sorting-and-pagination/)
