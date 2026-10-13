# 04 · Interview preparation

| File | What's in it |
|---|---|
| [theory-questions.md](theory-questions.md) | 83 concept questions with short answers, grouped by topic and linked to the lessons |
| [sql-problems.md](sql-problems.md) | 28 classic hands-on problems, easy → hard |
| [solutions.sql](solutions.sql) | Tested solutions for every problem, often with two approaches |

Every lesson README also ends with its own **Interview questions** section.

## A two-week plan

| Days | Do |
|---|---|
| 1–3 | [01-basics](../01-basics/) lessons + exercises. You should be able to write SELECT / WHERE / ORDER BY / UPDATE without looking anything up. |
| 4–6 | [02-intermediate](../02-intermediate/): GROUP BY, **joins**, subqueries, CASE. Joins and GROUP BY are the bulk of interview questions. |
| 7–8 | [Window functions](../03-advanced/02-window-functions/) and [CTEs](../03-advanced/01-common-table-expressions/). Then problems 1–15. |
| 9 | [Indexes](../03-advanced/04-indexes/), [query optimization](../03-advanced/10-query-optimization/). |
| 10 | [Transactions and ACID](../03-advanced/05-transactions-and-acid/), including the two-session demos. |
| 11 | [Normalization](../03-advanced/09-normalization/), views, procedures, triggers. |
| 12 | Problems 16–28 (gaps & islands, duplicates, retention). |
| 13 | [theory-questions.md](theory-questions.md) out loud. |
| 14 | Redo every problem you got wrong, without looking. Time yourself: aim for under 10 minutes for a medium problem. |

## Patterns that solve most problems

| You see… | Reach for… |
|---|---|
| "top N per …", "highest in each …" | `ROW_NUMBER()` / `RANK()` `OVER (PARTITION BY …)` |
| "Nth highest" | `DENSE_RANK()` |
| "never", "without", "missing" | `NOT EXISTS` or `LEFT JOIN … IS NULL` |
| "for every", "all of" | `GROUP BY … HAVING COUNT(DISTINCT …) = (SELECT COUNT …)` |
| "duplicates" | `GROUP BY … HAVING COUNT(*) > 1`; delete with `ROW_NUMBER() > 1` |
| "previous / next", "change since" | `LAG()` / `LEAD()` |
| "running", "cumulative" | `SUM() OVER (ORDER BY …)` |
| "consecutive", "streak" | gaps & islands: `value - ROW_NUMBER()` |
| "hierarchy", "chain", "all reports" | recursive CTE |
| "as columns", "per month side by side" | conditional aggregation (pivot) |
| "more than average of their group" | window `AVG() OVER (PARTITION BY …)` or correlated subquery |

## Practice platforms

LeetCode (Database problem set, *SQL 50*), HackerRank SQL, StrataScratch, DataLemur, and *SQL Murder Mystery* for fun.
