# 15 · JSON in SQL

Modern relational databases can store and query JSON documents next to normal columns. It's useful for data whose shape varies (product attributes, event payloads, API responses, user settings) without giving up SQL, joins and transactions.

## Storage types

| Database | Type | Notes |
|---|---|---|
| PostgreSQL | `JSONB` (use this) / `JSON` | `JSONB` is parsed binary: indexable, keys de-duplicated, key order not kept. `JSON` keeps the exact text. |
| MySQL 5.7+ | `JSON` | Binary format, validated on insert |
| Oracle 21c+ | `JSON` (earlier: `VARCHAR2`/`CLOB` + `IS JSON` check) | |
| SQL Server 2016+ | `NVARCHAR(MAX)` + `ISJSON()` check (2025: native `JSON` type) | |
| SQLite | `TEXT` + JSON1 functions (`->`, `->>`, `json_extract`) | |

## Reading values

| Task | PostgreSQL | MySQL | Oracle | SQL Server |
|---|---|---|---|---|
| Field as JSON | `doc -> 'brand'` | `doc -> '$.brand'` | `JSON_QUERY(doc, '$.brand')` | `JSON_QUERY(doc, '$.brand')` |
| Field as text | `doc ->> 'brand'` | `doc ->> '$.brand'` | `JSON_VALUE(doc, '$.brand')` | `JSON_VALUE(doc, '$.brand')` |
| Nested path | `doc #>> '{dims,width}'` / `doc -> 'dims' ->> 'width'` | `doc ->> '$.dims.width'` | `JSON_VALUE(doc, '$.dims.width')` | same |
| Array element | `doc -> 'tags' ->> 0` | `doc ->> '$.tags[0]'` | `JSON_VALUE(doc, '$.tags[0]')` | same |
| Standard SQL/JSON path | `jsonb_path_query(doc, '$.tags[*]')`, `JSON_VALUE` (PG 17) | — | ✔ | ✔ |

`->>` returns **text**; cast before comparing numbers: `(doc ->> 'ram_gb')::INT >= 16`.

## Filtering

```sql
WHERE doc ->> 'brand' = 'Acme'          -- field equals
WHERE doc @> '{"brand": "Acme"}'         -- PostgreSQL containment: can use a GIN index
WHERE doc ? 'warranty_years'             -- PostgreSQL: key exists
WHERE doc -> 'tags' ? 'wireless'         -- array contains a string
WHERE JSON_CONTAINS(doc, '"wireless"', '$.tags')   -- MySQL
```

## Turning JSON into rows (and back)

| Task | PostgreSQL | MySQL 8 | Oracle | SQL Server |
|---|---|---|---|---|
| Array → rows | `jsonb_array_elements(doc -> 'tags')` | `JSON_TABLE(...)` | `JSON_TABLE(...)` | `OPENJSON(doc, '$.tags')` |
| Object → key/value rows | `jsonb_each(doc)` | `JSON_TABLE` + `JSON_KEYS` | `JSON_TABLE` | `OPENJSON(doc)` |
| JSON → typed columns | `jsonb_to_record` / `JSON_TABLE` (PG 17) | `JSON_TABLE` | `JSON_TABLE` | `OPENJSON ... WITH (...)` |
| Rows → JSON | `to_jsonb(row)`, `jsonb_build_object`, `jsonb_agg` | `JSON_OBJECT`, `JSON_ARRAYAGG` | `JSON_OBJECT`, `JSON_ARRAYAGG` | `FOR JSON PATH` |

Building nested JSON in SQL (an order with its items) is a common way to serve an API response in **one** query.

## Modifying

| PostgreSQL | MySQL | Oracle | SQL Server |
|---|---|---|---|
| `jsonb_set(doc, '{price}', '99')`, `doc \|\| '{"k":1}'`, `doc - 'key'` | `JSON_SET`, `JSON_INSERT`, `JSON_REMOVE` | `JSON_TRANSFORM` (21c) / `JSON_MERGEPATCH` | `JSON_MODIFY` |

## Indexing JSON

| Database | How |
|---|---|
| PostgreSQL | `CREATE INDEX ON t USING GIN (doc);` (supports `@>`, `?`) or `GIN (doc jsonb_path_ops)` (smaller, `@>` only); B-tree expression index for one field: `CREATE INDEX ON t ((doc ->> 'brand'));` |
| MySQL | Index a generated column: `brand VARCHAR(50) AS (doc ->> '$.brand') STORED, INDEX (brand)`; or a functional index; multi-valued index for arrays |
| Oracle | Function-based index on `JSON_VALUE`, or a JSON search index |
| SQL Server | Computed column on `JSON_VALUE` + index |

## When to use JSON (and when not)

**Good fit:** attributes that differ per row (a laptop has RAM, a chair has material), raw payloads you store and rarely query, settings blobs, data you just pass through.

**Bad fit:** fields you filter, join or aggregate on all the time, values that need foreign keys or `CHECK` constraints, or data with a stable structure. Those belong in real columns. A common design: regular columns for the core fields, plus one JSONB column for the variable extras. Pull a JSON field out into a real column once it becomes important.

## Interview questions

1. **JSON vs JSONB in PostgreSQL?** JSON stores the original text (keeps whitespace, key order, duplicate keys) and re-parses on every access. JSONB stores a parsed binary form: faster to query, indexable with GIN, but drops key order/duplicates.
2. **`->` vs `->>`?** `->` returns JSON, `->>` returns text.
3. **How do you index a JSON field?** Expression index on the extracted value, GIN on the whole document (PG), generated column + index (MySQL), function-based index (Oracle).
4. **How do you turn a JSON array into rows?** `jsonb_array_elements` (PG), `JSON_TABLE` (MySQL/Oracle), `OPENJSON` (SQL Server).
5. **When should you not use a JSON column?** When the fields are stable, frequently queried, joined, or need constraints: use normal columns.
6. **How would you return an order with its items as one JSON document?** `jsonb_build_object(...)` with `jsonb_agg(...)` over the items, grouped by order.

## Files

- [examples.sql](examples.sql) · [exercises.sql](exercises.sql) · [mysql.sql](mysql.sql) · [oracle.sql](oracle.sql) · [sqlserver.sql](sqlserver.sql)

Next: [16 · Data warehousing and SCD](../16-data-warehousing-and-scd/)
