Indexes make searches faster.

Create index:

CREATE INDEX idx_department
ON employees(department);

Why?

Without index → full table scan
With index → faster lookup.