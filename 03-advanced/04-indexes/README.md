# 04 · Indexes

Without an index, finding `WHERE email = 'x'` means reading **every row** (a full table scan). An index is a separate, sorted data structure that maps column values to row locations, like the index at the back of a book.

```sql
CREATE INDEX idx_employees_dept ON employees (dept_id);
CREATE UNIQUE INDEX idx_customers_email ON customers (email);
DROP INDEX idx_employees_dept;                 -- MySQL: DROP INDEX idx ON employees;
```

## How a B-tree index works

```
                    [ 50000 | 100000 ]                     root
                   /        |         \
     [20000|35000]   [60000|80000]   [150000|200000]       branches
      /   |    \       /   |   \       /    |    \
   leaf pages: sorted values + pointers to rows, linked left ↔ right
```

- Lookup of one value: walk root → branch → leaf, about 3–4 page reads even for millions of rows: **O(log n)**.
- Range queries (`BETWEEN`, `>`, `<`, `LIKE 'abc%'`) and `ORDER BY` follow the linked leaves.
- B-tree is the default in every database.

## Index types

| Type | Good for | Where |
|---|---|---|
| **B-tree** | `=`, ranges, sorting, prefix `LIKE` | Everywhere (default) |
| **Hash** | `=` only | PostgreSQL, MySQL MEMORY |
| **GIN** | Arrays, JSONB, full-text search | PostgreSQL |
| **GiST / SP-GiST** | Geometry, ranges, nearest-neighbour | PostgreSQL |
| **BRIN** | Huge tables naturally ordered by a column (time series) | PostgreSQL |
| **Bitmap** | Low-cardinality columns in data warehouses | Oracle |
| **Full-text** | Word search | MySQL `FULLTEXT`, SQL Server, PG (GIN) |

## Clustered vs non-clustered

| | Clustered | Non-clustered (secondary) |
|---|---|---|
| What it is | The table rows themselves are stored in index order | Separate structure with pointers back to the rows |
| How many | One per table | Many |
| Where | SQL Server (PK by default), MySQL InnoDB (always the PK), Oracle "index-organized tables" | Everywhere |
| PostgreSQL | No persistent clustering (`CLUSTER` reorders once) | All indexes are secondary |

In InnoDB, secondary indexes store the **primary key** as the pointer, so a wide PK makes every index bigger.

## Composite (multi-column) indexes

```sql
CREATE INDEX idx_orders_cust_date ON orders (customer_id, order_date);
```

**Leftmost-prefix rule:** the index is sorted by `customer_id`, then `order_date` within each customer. It helps:

| Query | Uses the index? |
|---|---|
| `WHERE customer_id = 1` | ✔ |
| `WHERE customer_id = 1 AND order_date > '2025-06-01'` | ✔ (both columns) |
| `WHERE customer_id = 1 ORDER BY order_date` | ✔ (no sort needed) |
| `WHERE order_date > '2025-06-01'` | ✘ usually not (leading column missing) |

Column order: put columns used with `=` first, then the range/sort column.

## Covering indexes and index-only scans

If the index contains **every column the query needs**, the table isn't touched at all.

```sql
CREATE INDEX idx_orders_cust_inc ON orders (customer_id) INCLUDE (status);   -- PostgreSQL 11+, SQL Server
SELECT status FROM orders WHERE customer_id = 1;                            -- index-only scan
```

## Other useful kinds

- **Unique index:** enforces uniqueness (that's how `UNIQUE` and `PRIMARY KEY` are implemented).
- **Partial / filtered index:** indexes only some rows: `CREATE INDEX ... ON orders (order_date) WHERE status = 'pending';` (PostgreSQL, SQLite, SQL Server `WHERE`).
- **Expression / function-based index:** `CREATE INDEX ... ON customers (LOWER(email));` lets `WHERE LOWER(email) = ...` use an index (PostgreSQL, Oracle, MySQL 8.0.13+).

## When an index is NOT used

| Cause | Example | Fix |
|---|---|---|
| Function on the column | `WHERE UPPER(name) = 'ASHA'` | Expression index, or compare the raw column |
| Arithmetic on the column | `WHERE salary * 12 > 1200000` | `WHERE salary > 100000` |
| Leading wildcard | `WHERE name LIKE '%sha'` | Full-text / trigram index |
| Implicit type conversion | `WHERE phone = 98765` on a VARCHAR column | Compare with a string |
| Leading column of composite index missing | index `(a, b)`, `WHERE b = 1` | Index on `(b)` or `(b, a)` |
| Low selectivity | `WHERE is_active = true` when 95% are true | Scan is cheaper; the optimiser is right |
| `OR` across different columns | `WHERE a = 1 OR b = 2` | Separate indexes (bitmap OR) or `UNION` |
| Small table | 16 rows | Scan is cheaper |
| Stale statistics | After bulk loads | `ANALYZE` (PG), `ANALYZE TABLE` (MySQL), `DBMS_STATS` (Oracle) |

A predicate that *can* use an index is called **sargable** (Search ARGument ABLE).

## The cost of indexes

- Every `INSERT`, `DELETE`, and `UPDATE` of an indexed column must update **every** index.
- Indexes take disk and memory.
- Too many overlapping indexes slow writes and confuse the planner.

**Index:** primary keys (automatic), foreign keys, columns in frequent `WHERE`/`JOIN`/`ORDER BY`, columns with high selectivity.
**Don't index:** tiny tables, columns rarely queried, low-cardinality columns (alone), write-heavy tables beyond what's needed.

## EXPLAIN

| Database | Plan | Plan + actual run |
|---|---|---|
| PostgreSQL | `EXPLAIN query` | `EXPLAIN ANALYZE query` (executes it!) |
| MySQL | `EXPLAIN query` | `EXPLAIN ANALYZE query` (8.0.18+) |
| Oracle | `EXPLAIN PLAN FOR query; SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);` | `DBMS_XPLAN.DISPLAY_CURSOR` |
| SQL Server | Display Estimated Execution Plan | `SET STATISTICS PROFILE ON` |
| SQLite | `EXPLAIN QUERY PLAN query` | — |

What to look for in PostgreSQL: `Seq Scan` (full scan), `Index Scan`, `Index Only Scan`, `Bitmap Index Scan`; estimated vs actual rows; the most expensive node. In MySQL: `type` (`ALL` = full scan, `ref`/`range`/`const` = index), `key` (which index), `rows`.

More on reading plans in [10 · Query optimization](../10-query-optimization/).

## Interview questions

1. **What is an index and how does it speed up queries?** A sorted structure (usually a B-tree) that lets the engine jump to matching rows in O(log n) instead of scanning all rows.
2. **Clustered vs non-clustered index?** Clustered stores the table rows in index order (one per table); non-clustered is a separate structure pointing to rows (many allowed).
3. **Why not index every column?** Slower writes, more storage, and many indexes would never be used.
4. **What is a composite index and does column order matter?** An index on several columns; yes, it's usable only for queries that filter on a leftmost prefix.
5. **What is a covering index?** One that contains all columns a query needs, enabling an index-only scan.
6. **Why isn't my index used?** Function on the column, leading wildcard, type mismatch, low selectivity, missing leading column, stale stats, small table.
7. **Does a primary key create an index?** Yes, always (a unique index). A foreign key does in MySQL only.
8. **What is index selectivity / cardinality?** Distinct values ÷ rows. High selectivity (email) → index is very useful; low (gender) → rarely useful alone.
9. **B-tree vs hash index?** B-tree supports equality, ranges and ordering; hash supports only equality.

## Files

- [examples.sql](examples.sql): builds a 200,000-row table and shows plans before and after each index
- [exercises.sql](exercises.sql)
- [mysql.sql](mysql.sql): `EXPLAIN` in MySQL (`type: ALL` vs `ref`)

Next: [05 · Transactions and ACID](../05-transactions-and-acid/)
