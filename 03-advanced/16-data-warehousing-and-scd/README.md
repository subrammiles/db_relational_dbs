# 16 · Data warehousing, star schemas and slowly changing dimensions

Data-engineering and analytics interviews spend a lot of time here.

## OLTP vs OLAP

| | OLTP (operational) | OLAP (analytical / warehouse) |
|---|---|---|
| Purpose | Run the business: place orders, update stock | Analyse the business: revenue by month by region |
| Queries | Many small reads/writes by key | Few large scans and aggregations |
| Schema | Normalised (3NF) | Denormalised: star / snowflake |
| Data | Current state | History, often years |
| Storage | Row-oriented | Usually **columnar** (Snowflake, BigQuery, Redshift, ClickHouse, DuckDB) |
| Loaded by | The application | ETL / ELT pipelines |

## Dimensional modelling (Kimball)

```
               dim_date
                   │
dim_customer ── fact_sales ── dim_product
                   │
               dim_store
```

| Concept | Meaning | Example |
|---|---|---|
| **Fact table** | Measurable events: numbers you sum or count, plus foreign keys to dimensions | `fact_sales (date_key, customer_key, product_key, quantity, revenue)` |
| **Dimension table** | Descriptive context you filter and group by | `dim_product (product_key, name, category, brand)` |
| **Grain** | What one fact row represents. **Decide it first.** | "one row per order line" |
| **Surrogate key** | Warehouse-generated key for each dimension row (needed for history) | `customer_key` vs business key `customer_id` |
| **Star schema** | Fact table + denormalised dimensions, one join each | Most common |
| **Snowflake schema** | Dimensions normalised into sub-tables (`dim_product → dim_category`) | Less redundancy, more joins |
| **Date dimension** | One row per day with year, quarter, month, weekday, holiday flags... | Makes time analysis easy |
| **Conformed dimension** | One dimension shared by several fact tables | Same `dim_customer` for sales and support facts |
| **Degenerate dimension** | A dimension value kept in the fact table with no table of its own | `order_id` |

### Fact table types

| Type | Grain | Example |
|---|---|---|
| Transaction | One row per event | Each order line |
| Periodic snapshot | One row per entity per period | Account balance at each month end |
| Accumulating snapshot | One row per process, updated as it moves through stages | Order: placed → shipped → delivered dates |
| Factless | Events with no measure | Student attended class |

**Additive** measures can be summed across all dimensions (revenue); **semi-additive** only across some (balances: not across time); **non-additive** never (ratios: recompute from components).

## Slowly changing dimensions (SCD)

Dimension attributes change over time (a customer moves city). How do you keep history?

| Type | What happens on change | History | Example result |
|---|---|---|---|
| **Type 0** | Never change (retain original) | Original value only | `date_of_birth` |
| **Type 1** | **Overwrite** | None: old reports now show the new value | Fix typos, current-only attributes |
| **Type 2** | **Add a new row** with a new surrogate key; close the old row with `valid_to` / `is_current` | **Full** history | Customer moves Mumbai → Pune: two rows, old sales stay attributed to Mumbai |
| **Type 3** | Add a **column** for the previous value (`previous_city`) | Only one previous value | Region reorganisation, "before vs after" |
| **Type 4** | Current table + separate history table | Full, in another table | Fast-changing attributes |
| **Type 6** | 1 + 2 + 3: new rows (Type 2) **and** a `current_city` column updated on every row (Type 1) | Full + easy "as of now" | |

### SCD Type 2 table

| customer_key | customer_id | name | city | valid_from | valid_to | is_current |
|---|---|---|---|---|---|---|
| 1 | 101 | Aarav | Mumbai | 2024-01-05 | 2025-07-01 | false |
| 7 | 101 | Aarav | Pune | 2025-07-01 | 9999-12-31 | true |

- Facts store `customer_key`, so each sale points to the version that was true at the time.
- `valid_to` is **exclusive** here: the old row ends on the day the new one starts, so there are no gaps or overlaps.
- "Current" queries: `WHERE is_current`. "As of a date": `WHERE :d >= valid_from AND :d < valid_to`. (Some teams store an inclusive `valid_to` = day before and use `BETWEEN`; pick one convention and stick to it.)
- Use a far-future `valid_to` (`9999-12-31`) instead of NULL so range predicates stay simple.
- Loading is a two-step job: **expire** changed current rows, then **insert** new versions for changed and brand-new customers. Both steps go in one transaction. [examples.sql](examples.sql) does it with plain SQL; it can also be done with one `MERGE` plus an insert.

## ETL vs ELT, and other pipeline terms

| Term | Meaning |
|---|---|
| **ETL** | Extract → Transform (outside the warehouse) → Load |
| **ELT** | Extract → Load raw → Transform inside the warehouse with SQL (dbt). The modern default. |
| Staging table | Raw copy of source data before transformation |
| Incremental load | Only process rows changed since the last run (by `updated_at` watermark or CDC) |
| **CDC** (change data capture) | Stream inserts/updates/deletes from the source's log (Debezium, logical replication) |
| Idempotent load | Re-running the job gives the same result (use MERGE/upsert, delete-then-insert by partition) |
| Late-arriving data | Facts that arrive after their period was loaded; dimension rows missing when the fact arrives ("inferred members") |

## Interview questions

1. **Fact vs dimension table?** Facts hold measurable events and foreign keys; dimensions hold descriptive attributes to filter and group by.
2. **Star vs snowflake schema?** Star: denormalised dimensions, one join each, faster and simpler. Snowflake: normalised dimensions, less redundancy, more joins.
3. **What is the grain of a fact table and why decide it first?** What one row represents; it determines which dimensions and measures fit and prevents double counting.
4. **Explain SCD Types 1, 2 and 3.** Overwrite / new row per version with validity dates / previous-value column.
5. **How do you implement SCD Type 2?** Surrogate key, business key, valid_from, valid_to, is_current; on change, expire the current row and insert a new one, in one transaction.
6. **Why do warehouses use surrogate keys?** Several versions of the same business key must coexist (SCD2), sources may reuse or change keys, and integer keys join fast.
7. **ETL vs ELT?** Transform before loading vs load raw and transform inside the warehouse.
8. **Additive vs semi-additive measures?** Summable across all dimensions vs only some (balances can't be summed over time).
9. **What is a date dimension and why use one?** A table of every date with calendar attributes; avoids repeated date logic and supports fiscal calendars and holidays.
10. **Why are warehouses columnar?** Analytical queries read a few columns of many rows; columnar storage reads only those columns and compresses them well.
11. **How do you make a daily load idempotent?** Upsert/MERGE on keys, or delete-and-reload the day's partition within a transaction.

## Files

- [examples.sql](examples.sql): builds a star schema from the sample DB, a date dimension, SCD Types 1, 2 and 3, and point-in-time queries
- [exercises.sql](exercises.sql)

Back to the [course map](../../README.md) · Next: [04-interview](../../04-interview/)
