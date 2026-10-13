# SQL: basic to advanced, for learning and interviews

A hands-on SQL course built around one small sample database. Every lesson has a short explanation, runnable examples, exercises with solutions, and interview questions. PostgreSQL is the main dialect; MySQL, Oracle and SQLite differences are called out in each lesson, with dialect-specific scripts where they matter.

## Quick start

```bash
# 1. Install a database: see 00-setup/ (PostgreSQL recommended)
# 2. Load the sample data
createdb sqltutorial
psql -d sqltutorial -f sample-db/schema.sql
psql -d sqltutorial -f sample-db/seed.sql
# 3. Work through the lessons in order
psql -d sqltutorial -f 01-basics/04-select-and-where/examples.sql
```

## Course map

### [00 · Setup](00-setup/)
[PostgreSQL](00-setup/postgres.md) · [MySQL](00-setup/mysql.md) · [Oracle (Docker)](00-setup/oracle.md) · [SQLite](00-setup/sqlite.md) · [Sample database](sample-db/README.md)

### [01 · Basics](01-basics/)

| # | Lesson | Covers |
|---|---|---|
| 01 | [Introduction](01-basics/01-introduction/) | Tables, keys, relationships, DDL/DML/DCL/TCL, logical query order |
| 02 | [CREATE TABLE and data types](01-basics/02-create-table-and-data-types/) | Types per database, identity columns, CTAS, temp tables |
| 03 | [INSERT](01-basics/03-insert/) | Single/multi-row, INSERT…SELECT, RETURNING, Oracle INSERT ALL |
| 04 | [SELECT and WHERE](01-basics/04-select-and-where/) | Columns, expressions, comparisons, NULL comparisons |
| 05 | [Filtering operators](01-basics/05-filtering-operators/) | AND/OR/NOT, IN, BETWEEN, LIKE, regex, IS NULL, three-valued logic |
| 06 | [Sorting and pagination](01-basics/06-sorting-and-pagination/) | ORDER BY, NULLS FIRST/LAST, LIMIT/FETCH, keyset pagination, ROWNUM |
| 07 | [DISTINCT and aliases](01-basics/07-distinct-and-aliases/) | DISTINCT, COUNT(DISTINCT), DISTINCT ON, column/table aliases |
| 08 | [UPDATE and DELETE](01-basics/08-update-and-delete/) | Joined updates/deletes, DELETE vs TRUNCATE vs DROP, soft delete |
| 09 | [ALTER, DROP, TRUNCATE](01-basics/09-alter-drop-truncate/) | Changing structure safely, recycle bin |

### [02 · Intermediate](02-intermediate/)

| # | Lesson | Covers |
|---|---|---|
| 01 | [Aggregate functions](02-intermediate/01-aggregate-functions/) | COUNT/SUM/AVG/MIN/MAX, NULL handling, STRING_AGG, percentiles |
| 02 | [GROUP BY and HAVING](02-intermediate/02-group-by-and-having/) | Grouping rules, WHERE vs HAVING, finding duplicates |
| 03 | [Joins](02-intermediate/03-joins/) | Inner, left, right, full, cross, self, natural, USING, anti/semi joins, pitfalls |
| 04 | [Set operators](02-intermediate/04-set-operators/) | UNION (ALL), INTERSECT, EXCEPT/MINUS |
| 05 | [Subqueries](02-intermediate/05-subqueries/) | Scalar, list, derived tables, correlated, EXISTS, ANY/ALL, NOT IN trap |
| 06 | [CASE and NULL handling](02-intermediate/06-case-and-null-handling/) | CASE, COALESCE, NULLIF, NVL, DECODE, conditional aggregation |
| 07 | [Built-in functions](02-intermediate/07-built-in-functions/) | String, numeric, date and conversion functions across 4 databases |
| 08 | [Constraints and keys](02-intermediate/08-constraints-and-keys/) | PK, FK actions, UNIQUE, CHECK, DEFAULT, deferrable constraints |

### [03 · Advanced](03-advanced/)

| # | Lesson | Covers |
|---|---|---|
| 01 | [Common table expressions](03-advanced/01-common-table-expressions/) | WITH, recursive CTEs, hierarchies, series, Oracle CONNECT BY |
| 02 | [Window functions](03-advanced/02-window-functions/) | ROW_NUMBER/RANK/DENSE_RANK, LAG/LEAD, running totals, frames |
| 03 | [Views](03-advanced/03-views/) | Views, updatable views, WITH CHECK OPTION, materialized views |
| 04 | [Indexes](03-advanced/04-indexes/) | B-tree, composite, covering, partial, expression indexes, EXPLAIN |
| 05 | [Transactions and ACID](03-advanced/05-transactions-and-acid/) | ACID, isolation levels, MVCC, locking, deadlocks, savepoints |
| 06 | [Stored procedures and functions](03-advanced/06-stored-procedures-and-functions/) | PL/pgSQL, PL/SQL, MySQL procedures, dynamic SQL |
| 07 | [Triggers](03-advanced/07-triggers/) | BEFORE/AFTER/INSTEAD OF, audit logs, OLD/NEW |
| 08 | [Cursors](03-advanced/08-cursors/) | Explicit/implicit cursors, REF CURSOR, BULK COLLECT, why to avoid them |
| 09 | [Normalization](03-advanced/09-normalization/) | Anomalies, 1NF–BCNF, denormalization, star schema |
| 10 | [Query optimization](03-advanced/10-query-optimization/) | Reading plans, join algorithms, sargability, N+1, statistics |
| 11 | [Upsert and MERGE](03-advanced/11-upsert-and-merge/) | ON CONFLICT, ON DUPLICATE KEY, MERGE |
| 12 | [Pivot and advanced grouping](03-advanced/12-pivot-and-advanced-grouping/) | Pivot/unpivot, ROLLUP, CUBE, GROUPING SETS |
| 13 | [Security and permissions](03-advanced/13-security-and-permissions/) | Roles, GRANT/REVOKE, row-level security, SQL injection |
| 14 | [Partitioning, replication, sharding](03-advanced/14-partitioning-replication-sharding/) | Range/list/hash partitions, replicas, shards, CAP, backups |

### [04 · Interview preparation](04-interview/)
[83 theory questions](04-interview/theory-questions.md) · [28 hands-on problems](04-interview/sql-problems.md) · [solutions](04-interview/solutions.sql) · two-week study plan

## Lesson layout

```
NN-topic/
├── README.md       concept, syntax, dialect differences, pitfalls, interview questions
├── examples.sql    runnable PostgreSQL examples on the sample database
├── exercises.sql   practice tasks, each followed by its solution
├── mysql.sql       the same ideas in MySQL      (where it differs)
└── oracle.sql      the same ideas in Oracle     (where it differs)
```

## Testing the lessons

Every PostgreSQL script is run against a freshly loaded sample database:

```bash
PGHOST=localhost PGUSER=postgres PGPASSWORD=... PGDATABASE=sqltutorial scripts/run-all-postgres.sh
scripts/run-all-postgres.sh 03-advanced     # one section only
```
