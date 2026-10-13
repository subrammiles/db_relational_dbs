# 09 · Normalization and database design

**Normalization** organises tables so that each fact is stored **once**. That removes redundancy and the anomalies it causes.

## The anomalies

Start with one wide table that records orders:

| order_id | order_date | customer_name | customer_city | product | category | price | qty |
|---|---|---|---|---|---|---|---|
| 1 | 2025-01-10 | Aarav | Mumbai | Laptop | Electronics | 85000 | 1 |
| 1 | 2025-01-10 | Aarav | Mumbai | Mouse | Electronics | 800 | 1 |
| 2 | 2025-02-14 | Aarav | Mumbai | Notebook | Stationery | 250 | 10 |
| 3 | 2025-02-20 | Isha | Ahmedabad | Chair | Furniture | 12000 | 2 |

| Anomaly | Example |
|---|---|
| **Update** | Aarav moves to Pune: you must change 3 rows; miss one and the data contradicts itself |
| **Insert** | You can't add a new product until someone orders it (no order_id to put in the row) |
| **Delete** | Delete order 3 and you lose the only record that Isha exists and that Chairs cost 12000 |

## Functional dependency

`A → B` ("A determines B") means: rows with the same A always have the same B. Here `customer_name → customer_city` and `product → category, price`. Normalization is about making sure every dependency is on a **key**.

## Normal forms

| Form | Rule | Plain English |
|---|---|---|
| **1NF** | Atomic values, no repeating groups, each row unique (has a key) | One value per cell. No `phones = '123, 456'`, no `phone1, phone2, phone3` columns |
| **2NF** | 1NF + no **partial** dependency: every non-key column depends on the **whole** key | Only matters with composite keys. In `order_lines (order_id, product_id, qty, product_name)`, `product_name` depends only on `product_id` → move it out |
| **3NF** | 2NF + no **transitive** dependency: non-key columns don't depend on other non-key columns | In `employees (emp_id, dept_id, dept_name)`, `dept_name` depends on `dept_id`, not on `emp_id` → move to `departments` |
| **BCNF** | Every determinant is a candidate key | Stricter 3NF; differs only with overlapping candidate keys (rare) |
| **4NF** | No multi-valued dependencies | Don't store two independent lists in one table (e.g. a teacher's subjects × languages) |
| **5NF** | No join dependencies | Rarely discussed outside theory |

The classic memory aid for 3NF: every non-key attribute must depend on **"the key, the whole key, and nothing but the key."**

## Normalizing the example

1. **1NF:** already one value per cell; key = `(order_id, product)`.
2. **2NF:** `order_date`, `customer_*` depend only on `order_id`; `category`, `price` depend only on `product`. Split:
   - `orders (order_id, order_date, customer_name, customer_city)`
   - `products (product, category, price)`
   - `order_items (order_id, product, qty)`
3. **3NF:** in `orders`, `customer_city` depends on `customer_name`, not on `order_id`. Split:
   - `customers (customer_id, name, city)`
   - `orders (order_id, order_date, customer_id)`

That's exactly the shape of the tutorial's [sample database](../../sample-db/README.md). [examples.sql](examples.sql) does this migration in SQL.

Note that `order_items.unit_price` looks like a duplicate of `products.price`, but it isn't: it records the **price at the time of sale**. Historical facts belong with the event.

## Denormalization

Deliberately adding redundancy **for read performance**, accepting the cost of keeping copies in sync.

| Technique | Example |
|---|---|
| Stored aggregates | `customers.lifetime_value`, `posts.comment_count` |
| Copied columns | `order_items.product_name` to avoid a join in a hot query |
| Summary / reporting tables | Daily revenue table filled by a nightly job |
| Materialized views | See [lesson 03](../03-views/) |

Normalize OLTP (transactional) systems to 3NF by default; denormalize specific hot paths when measurements show the need. Data warehouses (OLAP) deliberately use **star schemas**: a central **fact** table (sales: amounts, quantities, foreign keys) surrounded by denormalised **dimension** tables (date, product, customer, store). A **snowflake** schema normalises the dimensions further.

## Design checklist

- Every table has a primary key (usually a surrogate `id`) plus `UNIQUE` on natural keys.
- Many-to-many → junction table with a composite PK.
- Use the right types (`DATE` not `VARCHAR`, `NUMERIC` for money).
- Foreign keys for every relationship, indexed.
- `NOT NULL` wherever a value is always required.
- Consistent naming (`snake_case`, singular or plural, `<table>_id`).
- Don't store derived values unless you have a reason (and a mechanism to keep them correct).

## Interview questions

1. **What is normalization and why do it?** Organising data so each fact is stored once, to avoid update/insert/delete anomalies and keep data consistent.
2. **Explain 1NF, 2NF, 3NF.** Atomic values; no partial dependency on a composite key; no transitive dependency between non-key columns.
3. **Difference between 3NF and BCNF?** BCNF requires every determinant to be a candidate key; 3NF allows a non-key determinant if the dependent attribute is part of a candidate key.
4. **What is denormalization and when would you do it?** Adding redundancy to speed up reads, for read-heavy paths, reporting and warehouses.
5. **What is a functional dependency?** A → B: knowing A tells you B.
6. **Star vs snowflake schema?** Star: fact table + denormalised dimensions (fewer joins). Snowflake: dimensions are normalised into more tables.
7. **OLTP vs OLAP?** OLTP: many small transactions, normalised, row-oriented. OLAP: large analytical queries, denormalised/star schemas, often columnar storage.
8. **How would you design the schema for (an online shop / a library / a hospital)?** Identify entities, their keys, relationships (1:N → FK, M:N → junction table), then check 3NF. The sample DB is a worked answer for a shop.

## Files

- [examples.sql](examples.sql): normalises the flat table above step by step

Next: [10 · Query optimization](../10-query-optimization/)
