# Classic SQL interview problems

Try each one before looking at [solutions.sql](solutions.sql). Problems 1–15 use the [sample database](../sample-db/README.md); 16–28 create their own small tables (also in `solutions.sql`). Each solution is tested against PostgreSQL by `scripts/run-all-postgres.sh`.

Difficulty: 🟢 easy · 🟡 medium · 🔴 hard

## Using the sample database

| # | Problem | Level | Key idea |
|---|---|---|---|
| 1 | Second highest salary (return NULL if there isn't one) | 🟢 | `MAX` below `MAX`, or `DENSE_RANK` |
| 2 | **Nth** highest salary, as a reusable query (try N = 3) | 🟡 | `DENSE_RANK()` / `OFFSET n-1` on distinct values |
| 3 | Highest-paid employee(s) in each department, including ties | 🟡 | `RANK() OVER (PARTITION BY ...)` or correlated `MAX` |
| 4 | Top 2 earners per department | 🟡 | `ROW_NUMBER()` ≤ 2 |
| 5 | Employees who earn more than their manager | 🟢 | Self join |
| 6 | Employees who earn more than their department's average | 🟡 | Correlated subquery or window `AVG` |
| 7 | Departments with no employees | 🟢 | Anti-join (`NOT EXISTS` / `LEFT JOIN ... IS NULL`) |
| 8 | Customers who never placed an order | 🟢 | Anti-join |
| 9 | Each manager with their number of direct reports, including managers with 1 | 🟢 | Self join + `GROUP BY` |
| 10 | The full management chain from every employee up to the CEO | 🔴 | Recursive CTE |
| 11 | Customers who ordered in every month of Q1 2025 / who bought every Electronics product (relational division) | 🔴 | `GROUP BY ... HAVING COUNT(DISTINCT ...) = (SELECT COUNT ...)` |
| 12 | Each customer's first order and last order dates, and the number of days between them | 🟢 | `MIN`/`MAX` + date arithmetic |
| 13 | Month-over-month revenue growth % | 🟡 | `LAG()` |
| 14 | Running total of revenue by date, and the date it first passed 300,000 | 🟡 | `SUM() OVER (ORDER BY ...)` then filter |
| 15 | The product category with the highest revenue in each country | 🟡 | Aggregate → `RANK()` per partition |

## Using their own tables

| # | Problem | Level | Key idea |
|---|---|---|---|
| 16 | Find duplicate emails in a `users` table | 🟢 | `GROUP BY ... HAVING COUNT(*) > 1` |
| 17 | **Delete** duplicate rows, keeping the one with the smallest id | 🟡 | `ROW_NUMBER()` or self-join `DELETE` |
| 18 | Users who logged in on **3 or more consecutive days** | 🔴 | Gaps & islands: `date - ROW_NUMBER()` |
| 19 | Find the **missing** ids in a sequence (gaps) | 🟡 | `generate_series` anti-join, or `LEAD()` |
| 20 | Group consecutive rows with the same status into ranges (islands) | 🔴 | Difference of two `ROW_NUMBER()`s |
| 21 | Swap the values `'M'` and `'F'` in one `UPDATE` | 🟢 | `CASE` |
| 22 | Pivot: one row per student, one column per subject | 🟡 | Conditional aggregation |
| 23 | Each customer's **median** order value | 🟡 | `PERCENTILE_CONT` / window trick |
| 24 | Friends of friends who aren't already friends (recommendations) | 🔴 | Self join on an edge table + `EXCEPT` |
| 25 | Retention: % of users active in month 1 who came back in month 2 | 🔴 | Self join on activity by month |
| 26 | Rank of each score (dense, no gaps), "LeetCode Rank Scores" | 🟢 | `DENSE_RANK()` |
| 27 | Numbers that appear at least **3 times consecutively** | 🟡 | `LAG` / `LEAD` or self join on id |
| 28 | Cumulative balance per account from a transactions ledger, and the first time each account went negative | 🟡 | `SUM() OVER (PARTITION BY ... ORDER BY ...)` |

## How to answer in an interview

1. **Clarify:** ties? NULLs? What if there's no answer (return NULL vs no row)? Which database?
2. **State the approach** in a sentence before writing ("rank salaries per department and keep rank 1").
3. **Write it step by step**, CTEs make that easy to follow.
4. **Test mentally on edge cases:** empty table, ties, NULLs, one row.
5. **Mention alternatives and performance:** "on a big table I'd want an index on `(dept_id, salary)`".
