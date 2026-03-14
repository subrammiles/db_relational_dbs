Indexes make searches faster.

Create index:

CREATE INDEX idx_department
ON employees(department);

Why?

Without index → full table scan
With index → faster lookup.

Indexing in SQL is used to speed up data retrieval from a table. Without an index, the database must scan every row to find the data you want, which becomes slow when tables contain millions of rows.