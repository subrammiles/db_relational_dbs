# SQL and database theory: interview questions

Short answers you can say out loud. Each section links to the lesson with the full explanation and runnable examples.

## Fundamentals · [01-basics](../01-basics/)

1. **What is SQL?** A declarative language for defining, querying and changing data in relational databases: you describe *what* you want, the database decides *how*.
2. **What are DDL, DML, DQL, DCL and TCL?** Definition (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`), manipulation (`INSERT`, `UPDATE`, `DELETE`, `MERGE`), query (`SELECT`), control (`GRANT`, `REVOKE`), transaction control (`COMMIT`, `ROLLBACK`, `SAVEPOINT`).
3. **In what order is a SELECT evaluated?** `FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT`. That's why aliases work in `ORDER BY` but not in `WHERE`.
4. **DELETE vs TRUNCATE vs DROP?** DELETE removes chosen rows, logged, fires triggers, can roll back. TRUNCATE empties the table fast as DDL, resets identity in some DBs, not rollback-able in Oracle/MySQL. DROP removes the table itself.
5. **CHAR vs VARCHAR?** Fixed length padded with spaces vs variable length.
6. **What is NULL?** Missing/unknown. Comparisons with it are UNKNOWN; use `IS NULL`. Aggregates skip it, except `COUNT(*)`.
7. **What does `NOT IN` do when the list contains NULL?** Returns no rows. Use `NOT EXISTS`.
8. **What is the difference between `WHERE` and `HAVING`?** WHERE filters rows before grouping; HAVING filters groups after aggregation and can use aggregates.
9. **UNION vs UNION ALL?** UNION removes duplicates (sort/hash cost); UNION ALL keeps them and is faster.
10. **How do you paginate, and why is OFFSET slow for deep pages?** `LIMIT/OFFSET` or `OFFSET ... FETCH`; OFFSET must read and discard skipped rows. Keyset pagination (`WHERE id > last_id`) uses an index.
11. **Is `BETWEEN` inclusive?** Yes, on both ends.
12. **COUNT(\*) vs COUNT(col) vs COUNT(DISTINCT col)?** All rows / non-NULL values / distinct non-NULL values.

## Keys, constraints and design · [constraints](../02-intermediate/08-constraints-and-keys/) · [normalization](../03-advanced/09-normalization/)

13. **Primary key vs unique key?** One PK, never NULL, identifies the row; many unique keys, NULLs allowed.
14. **What is a foreign key?** A column that must match a key in another table, enforcing referential integrity.
15. **Composite key?** A key made of multiple columns, e.g. `(order_id, product_id)`.
16. **Surrogate vs natural key?** Generated meaningless id vs real-world identifier. Common: surrogate PK + unique natural key.
17. **What does `ON DELETE CASCADE` do?** Deleting a parent row deletes its child rows.
18. **What is normalization? Explain 1NF, 2NF, 3NF.** Storing each fact once. 1NF atomic values; 2NF no partial dependency on part of a composite key; 3NF no transitive dependency between non-key columns.
19. **BCNF?** Every determinant is a candidate key.
20. **What is denormalization and when is it appropriate?** Adding redundancy for read speed: reporting, hot read paths, data warehouses.
21. **OLTP vs OLAP?** Many small transactions on normalised data vs large analytical queries on denormalised (star schema), often columnar, data.
22. **Star vs snowflake schema?** Fact table with denormalised dimensions vs normalised dimensions.
23. **How do you model many-to-many?** A junction table with a foreign key to each side.

## Joins and subqueries · [joins](../02-intermediate/03-joins/) · [subqueries](../02-intermediate/05-subqueries/)

24. **Types of joins?** INNER, LEFT, RIGHT, FULL OUTER, CROSS, self join; NATURAL and USING are shorthand forms.
25. **Why might a LEFT JOIN behave like an INNER JOIN?** A WHERE condition on the right table removes the NULL rows; put it in the ON clause.
26. **A has 5 rows, B has 4. Min/max rows of A INNER JOIN B? A LEFT JOIN B? A CROSS JOIN B?** 0–20, 5–20, exactly 20.
27. **What is a self join?** Joining a table to itself, e.g. employees to their managers.
28. **What is a correlated subquery?** A subquery that references the outer row, logically evaluated per row.
29. **IN vs EXISTS?** IN compares to a list; EXISTS tests for any matching row. Similar performance today; NOT EXISTS is NULL-safe.
30. **Subquery vs JOIN vs CTE?** Joins bring columns together; subqueries/EXISTS test or compute values; CTEs name intermediate steps for readability and recursion.
31. **What is a recursive CTE used for?** Hierarchies (org charts, categories), graphs, generating series.

## Window functions · [window functions](../03-advanced/02-window-functions/)

32. **What is a window function?** A calculation over related rows that keeps every row (vs GROUP BY, which collapses them).
33. **ROW_NUMBER vs RANK vs DENSE_RANK?** 1,2,3,4 / 1,2,2,4 / 1,2,2,3 for a tie at second place.
34. **What do PARTITION BY and ORDER BY do inside OVER()?** Split rows into groups / order within each group (which also turns aggregates into running totals).
35. **LAG and LEAD?** Value from a previous / following row.
36. **Why can't you filter on ROW_NUMBER() in WHERE?** Window functions are computed after WHERE; wrap in a CTE/subquery.
37. **ROWS vs RANGE?** Physical rows vs peer groups of equal ORDER BY values.

## Indexes and performance · [indexes](../03-advanced/04-indexes/) · [optimization](../03-advanced/10-query-optimization/)

38. **What is an index?** A sorted structure (usually a B-tree) that finds rows without scanning the table.
39. **Clustered vs non-clustered index?** Table stored in index order (one per table) vs separate structure with row pointers (many).
40. **Composite index and column order?** Usable only for a leftmost prefix of its columns; put equality columns first, then range/sort.
41. **Covering index?** Contains all columns a query needs → index-only scan.
42. **When is an index not used?** Function on the column, leading wildcard, type mismatch, low selectivity, leading column missing, stale stats, tiny table.
43. **Downsides of indexes?** Slower writes, storage, maintenance.
44. **What is a sargable predicate?** One that can use an index seek: the column isn't wrapped in a function/expression.
45. **How do you tune a slow query?** EXPLAIN ANALYZE, compare estimated vs actual rows, fix indexes/sargability/statistics, rewrite, re-measure.
46. **Nested loop vs hash join vs merge join?** Index lookups per outer row (small outer) / hash the smaller input (large unsorted) / walk two sorted inputs.
47. **What is the N+1 problem?** One query for a list plus one per item; fix with a join or batched IN.

## Transactions and concurrency · [transactions](../03-advanced/05-transactions-and-acid/)

48. **What is ACID?** Atomicity (all or nothing), Consistency (rules always hold), Isolation (no interference), Durability (committed = permanent).
49. **Isolation levels and what they prevent?** READ UNCOMMITTED (nothing), READ COMMITTED (dirty reads), REPEATABLE READ (+ non-repeatable reads), SERIALIZABLE (+ phantoms).
50. **Default isolation in PostgreSQL / MySQL / Oracle / SQL Server?** READ COMMITTED / REPEATABLE READ / READ COMMITTED / READ COMMITTED.
51. **Dirty read, non-repeatable read, phantom read?** Reading uncommitted data / same row changes between reads / new rows appear between reads.
52. **What is MVCC?** Multiple row versions so readers see a snapshot and don't block writers.
53. **What is a deadlock? How do you avoid it?** Two transactions each waiting for the other's lock; lock in a consistent order, keep transactions short, retry.
54. **Optimistic vs pessimistic locking?** Version check at write time vs `SELECT ... FOR UPDATE` at read time.
55. **What is a savepoint?** A marker inside a transaction you can roll back to without undoing everything.
56. **Is DDL transactional?** PostgreSQL/SQL Server yes; Oracle/MySQL commit implicitly.

## Database objects · [views](../03-advanced/03-views/) · [procedures](../03-advanced/06-stored-procedures-and-functions/) · [triggers](../03-advanced/07-triggers/) · [cursors](../03-advanced/08-cursors/)

57. **View vs materialized view?** Stored query run each time vs stored result refreshed on demand.
58. **Can you update through a view?** Yes for simple single-table views; otherwise with INSTEAD OF triggers.
59. **Stored procedure vs function?** Function returns a value and is usable in SQL; procedure is CALLed, can use OUT params and manage transactions.
60. **Pros and cons of stored procedures?** Fewer round trips, security, central logic vs harder versioning/testing, lock-in, DB-tier scaling.
61. **What is a trigger? BEFORE vs AFTER?** Automatic code on DML; BEFORE can modify/reject the row, AFTER reacts to the applied change.
62. **What are OLD and NEW?** The row before and after the change inside a trigger.
63. **What is a cursor and why avoid it?** Row-by-row processing; set-based SQL is usually far faster.
64. **What is a sequence?** A database object that generates unique numbers, used for ids (`NEXTVAL`).

## Security · [security](../03-advanced/13-security-and-permissions/)

65. **What is SQL injection and how do you prevent it?** User input altering SQL text; use parameterised queries, never concatenation.
66. **GRANT and REVOKE?** Give and remove privileges or roles.
67. **What is a role?** A named set of privileges assigned to users.
68. **Principle of least privilege?** Give each account only what it needs.
69. **Row-level security?** Policies that filter which rows each user sees or changes.

## Scaling and architecture · [partitioning](../03-advanced/14-partitioning-replication-sharding/)

70. **Partitioning vs sharding?** Split a table within one server vs spread data across servers.
71. **Replication types?** Sync vs async; physical vs logical; primary-replica vs multi-primary.
72. **What is replication lag?** Delay before replicas see primary writes; route read-after-write to the primary.
73. **Vertical vs horizontal scaling?** Bigger machine vs more machines.
74. **What is the CAP theorem?** During a network partition, a distributed system must choose consistency or availability.
75. **SQL vs NoSQL: when would you choose each?** Relational for structured data, integrity and complex queries; NoSQL for flexible schemas, massive scale or specific access patterns (key-value, documents, graphs).
76. **What are RPO and RTO?** Acceptable data loss and acceptable downtime after a failure.

## Vendor-specific quick facts

77. **What is `DUAL` in Oracle?** A one-row dummy table for selecting expressions.
78. **ROWNUM vs ROW_NUMBER()?** ROWNUM is assigned before ORDER BY; ROW_NUMBER follows the ORDER BY you give.
79. **NVL vs COALESCE?** NVL is Oracle, two arguments; COALESCE is standard, many arguments, short-circuits.
80. **`''` vs NULL in Oracle?** The empty string is NULL in Oracle.
81. **MySQL storage engines?** InnoDB (default; transactions, row locks, FKs) vs MyISAM (no transactions/FKs, table locks).
82. **PostgreSQL VACUUM?** Reclaims space from dead row versions created by MVCC updates/deletes and updates visibility info.
83. **`SERIAL` vs `IDENTITY` in PostgreSQL?** SERIAL is a legacy shorthand for a sequence default; IDENTITY is the SQL-standard replacement.
