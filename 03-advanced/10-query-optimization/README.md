# 10 · Query optimization and execution plans

## How a query runs

```
SQL text → Parser → Rewriter (views, rules) → Planner/Optimizer → Executor → rows
                                                    ▲
                                    table statistics (row counts, value distributions)
```

The optimizer generates candidate plans (which index, which join order, which join algorithm) and picks the one with the lowest **estimated cost**. Estimates come from **statistics**, so stale statistics mean bad plans.

## Reading an EXPLAIN plan (PostgreSQL)

```
Hash Join  (cost=1.36..2.68 rows=15 width=64) (actual time=0.03..0.04 rows=15 loops=1)
  Hash Cond: (e.dept_id = d.dept_id)
  ->  Seq Scan on employees e  (cost=0.00..1.16 rows=16 ...)
  ->  Hash  (cost=1.06..1.06 rows=6 ...)
        ->  Seq Scan on departments d  (cost=0.00..1.06 rows=6 ...)
```

- Read **inside-out, bottom-up**: the most indented nodes run first and feed their parents.
- `cost=startup..total`: arbitrary units; compare plans, not absolute numbers.
- `rows`: estimated rows. With `EXPLAIN ANALYZE` you also get **actual** rows and time. **A big gap between estimated and actual rows is the #1 sign of a bad plan.**
- `loops`: how many times the node ran (multiply time by loops).
- `EXPLAIN (ANALYZE, BUFFERS)` adds pages read from cache vs disk.

### Scan types

| Node | Meaning |
|---|---|
| Seq Scan | Reads the whole table |
| Index Scan | Walks the index, fetches each matching row from the table |
| Index Only Scan | Answers from the index alone |
| Bitmap Index Scan + Bitmap Heap Scan | Collects matching row locations first, then reads table pages in order. Good for medium selectivity, and for combining indexes (`BitmapAnd`/`BitmapOr`) |

### Join algorithms

| Algorithm | How | Best when |
|---|---|---|
| **Nested Loop** | For each outer row, look up matches in the inner (ideally via an index) | Small outer input; indexed inner |
| **Hash Join** | Build a hash table on the smaller input, probe with the larger | Large unsorted inputs, equality joins |
| **Merge Join** | Sort both inputs on the key, walk them together | Both inputs already sorted (indexes) or very large |

## Optimization checklist

**Write sargable predicates**

| Slow | Fast |
|---|---|
| `WHERE YEAR(order_date) = 2025` | `WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01'` |
| `WHERE salary * 12 > 1200000` | `WHERE salary > 100000` |
| `WHERE LOWER(email) = 'x'` (no expression index) | expression index, or store emails lower-cased |
| `WHERE phone = 98765` (VARCHAR column) | `WHERE phone = '98765'` |
| `WHERE name LIKE '%son'` | full-text / trigram index, or reverse-string index |

**Select less**
- Name the columns you need instead of `SELECT *` (enables index-only scans, less I/O and network).
- Paginate with keyset pagination for deep pages ([basics 06](../../01-basics/06-sorting-and-pagination/)).
- Filter early: in `WHERE`, not `HAVING`, when the condition isn't on an aggregate.

**Join and aggregate sensibly**
- Index foreign keys and join columns.
- Use `EXISTS` for "has any" checks instead of `JOIN` + `DISTINCT`.
- Prefer `NOT EXISTS` to `NOT IN` (correctness with NULLs, and often a better anti-join plan).
- Aggregate before joining when a join would multiply rows (fan-out).
- `UNION ALL` instead of `UNION` when duplicates are impossible or fine.
- Replace correlated subqueries in `SELECT` with a join + `GROUP BY` or a window function on large tables.

**Avoid the N+1 problem**
An app runs 1 query for a list of 100 orders, then 1 query per order for its items = 101 round trips. Fetch everything with one join or one `WHERE order_id IN (...)` query. ORMs cause this a lot (use eager loading).

**Batch writes**
Multi-row `INSERT`s, `COPY`/`LOAD DATA` for bulk loads, one transaction per batch instead of per row, and drop/recreate secondary indexes around huge loads.

**Keep statistics and storage healthy**
- `ANALYZE` after large data changes (autovacuum usually handles it).
- PostgreSQL: `VACUUM` reclaims dead row versions left by MVCC; watch table bloat.
- MySQL: `ANALYZE TABLE`, `OPTIMIZE TABLE`. Oracle: `DBMS_STATS.GATHER_TABLE_STATS`.

**Find the slow queries first**
- PostgreSQL: `pg_stat_statements` extension, `log_min_duration_statement`, `auto_explain`.
- MySQL: slow query log, `performance_schema`, `sys.statements_with_runtimes_in_95th_percentile`.
- Oracle: AWR / ASH reports, `V$SQL`.

Optimise what's actually slow and frequent: a 50 ms query run 10,000 times a minute matters more than a 5 s monthly report.

**Beyond the query**
Connection pooling (PgBouncer, HikariCP), caching (Redis) for hot reads, read replicas, partitioning very large tables ([lesson 14](../14-partitioning-replication-sharding/)), and more RAM so the working set fits in memory.

## Interview questions

1. **How do you approach a slow query?** Reproduce it, `EXPLAIN ANALYZE`, find the expensive node and estimate-vs-actual mismatches, check indexes and sargability, check statistics, rewrite, measure again.
2. **What is an execution plan?** The tree of operations (scans, joins, sorts) the database chose to run a query, with cost estimates.
3. **What's the difference between EXPLAIN and EXPLAIN ANALYZE?** EXPLAIN shows the estimated plan; ANALYZE runs the query and adds actual rows and timings.
4. **Nested loop vs hash join vs merge join?** See the table.
5. **What is the N+1 query problem?** One query for a list plus one per item; fix with a join or a batched `IN` query.
6. **What does "sargable" mean?** A predicate the engine can satisfy with an index seek: the column isn't wrapped in a function or expression.
7. **Why might the optimizer choose a full table scan even though an index exists?** The query returns a large fraction of rows, the table is small, statistics are stale, or the predicate isn't sargable.
8. **What are database statistics?** Row counts and value distributions (histograms, most common values) the optimizer uses to estimate how many rows each step will produce.

## Files

- [examples.sql](examples.sql): plans for scans, the three join algorithms, rewrites and the N+1 pattern

Next: [11 · Upsert and MERGE](../11-upsert-and-merge/)
