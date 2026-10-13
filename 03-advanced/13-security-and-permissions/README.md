# 13 · Security: users, roles, privileges, row-level security and SQL injection

## Users and roles

| Concept | PostgreSQL | MySQL | Oracle |
|---|---|---|---|
| User | `CREATE ROLE app LOGIN PASSWORD '...'` (`CREATE USER` = role with LOGIN) | `CREATE USER 'app'@'host' IDENTIFIED BY '...'` | `CREATE USER app IDENTIFIED BY ...` (a user **is** a schema) |
| Role / group | `CREATE ROLE readonly` (no LOGIN) | `CREATE ROLE 'readonly'` (8.0+) | `CREATE ROLE readonly` |
| Assign role | `GRANT readonly TO app` | `GRANT 'readonly' TO 'app'@'host'` + `SET DEFAULT ROLE` | `GRANT readonly TO app` |

**Grant privileges to roles, then roles to users.** When someone changes team you change their role membership, not dozens of grants.

## GRANT and REVOKE (DCL)

```sql
GRANT SELECT ON employees TO reporting;
GRANT SELECT, INSERT, UPDATE ON orders TO app_rw;
GRANT UPDATE (email) ON customers TO support;           -- column-level
GRANT EXECUTE ON FUNCTION transfer(int,int,numeric) TO app_rw;
GRANT reporting TO alice;                               -- role membership
REVOKE INSERT ON orders FROM app_rw;
GRANT SELECT ON employees TO lead WITH GRANT OPTION;     -- lead may grant it onwards
```

| Privilege | Allows |
|---|---|
| `SELECT` | Read rows |
| `INSERT` / `UPDATE` / `DELETE` | Change rows |
| `TRUNCATE`, `REFERENCES`, `TRIGGER` | (PostgreSQL) empty the table, create FKs to it, create triggers on it |
| `USAGE` on schema | Access objects in the schema at all (PostgreSQL) |
| `CREATE` on schema/database | Create new objects |
| `EXECUTE` | Run a function/procedure |
| `ALL PRIVILEGES` | Everything on that object |

PostgreSQL extras:
- `ALTER DEFAULT PRIVILEGES ... GRANT SELECT ON TABLES TO reporting;` so **future** tables get the grant too.
- Since v15 the `public` schema is no longer writable by everyone.
- `pg_read_all_data` / `pg_write_all_data` predefined roles (v14+).

## Principle of least privilege

- The application connects as a role that can only do what the app needs (usually no DDL, no `DROP`, no `TRUNCATE`).
- Migrations run as a separate owner role.
- Reporting tools get read-only roles, often on a replica.
- Nobody uses the superuser (`postgres`, `root`, `SYS`) for daily work.
- Expose sensitive tables through **views** or **SECURITY DEFINER functions** that return only what's allowed.

## Row-level security (RLS)

Restricts **which rows** each user can see or change, enforced by the database for every query.

```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY own_orders ON orders
    USING (customer_id = current_setting('app.customer_id')::int);
```

PostgreSQL: `CREATE POLICY`. Oracle: Virtual Private Database (`DBMS_RLS`). SQL Server: security policies. MySQL: none (use views).
Table owners and superusers bypass RLS unless `FORCE ROW LEVEL SECURITY` is set.

## SQL injection

Building SQL by **concatenating user input** lets an attacker change the query.

```python
# VULNERABLE
cursor.execute("SELECT * FROM users WHERE email = '" + email + "'")
# email = "x' OR '1'='1"  →  WHERE email = 'x' OR '1'='1'   → returns every user
# email = "x'; DROP TABLE users; --"
```

**Defences:**

1. **Parameterised queries / prepared statements:** the value is sent separately from the SQL text and is never parsed as SQL.
   ```python
   cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
   ```
2. In stored code: bind variables (`EXECUTE ... USING`, `EXECUTE IMMEDIATE ... USING`), and `format('%I')` / `quote_ident` / `DBMS_ASSERT` for identifiers that can't be parameters.
3. Allow-lists for things like sort columns (`ORDER BY` can't be a parameter).
4. Least privilege, so a successful injection can do less damage.
5. ORMs help, but raw-SQL escape hatches in ORMs are vulnerable too.

Escaping quotes by hand is **not** a reliable defence.

## Other security topics worth knowing

- **Encryption in transit:** TLS for client connections (`sslmode=require`/`verify-full`).
- **Encryption at rest:** disk/volume encryption, TDE (Oracle, SQL Server, MySQL Enterprise).
- **Hash passwords** in your application tables with bcrypt/argon2, never store them plain (or with plain SHA/MD5).
- **Auditing:** pgAudit, MySQL audit plugin, Oracle Unified Auditing.
- **Masking** sensitive data for non-production copies.

## Interview questions

1. **GRANT vs REVOKE?** GRANT gives a privilege or role; REVOKE removes it.
2. **What is a role?** A named bundle of privileges that can be granted to users (or other roles).
3. **What is the principle of least privilege?** Every account gets only the access it needs.
4. **What is SQL injection and how do you prevent it?** Attacker-controlled input changes your SQL; prevent with parameterised queries, never string concatenation.
5. **Can you pass a table name as a bind parameter?** No; parameters are values only. Validate identifiers against an allow-list or quote them with `quote_ident`/`%I`.
6. **What is row-level security?** Database-enforced policies that filter which rows a user can read or write.
7. **How can views improve security?** Grant access to a view that hides columns/rows instead of to the base table.
8. **What does WITH GRANT OPTION do?** Lets the grantee grant the same privilege to others.

## Files

- [examples.sql](examples.sql): roles, grants, `SET ROLE` to test them, RLS and a safe-dynamic-SQL function (needs a role with `CREATEROLE`, e.g. `postgres`)
- [exercises.sql](exercises.sql)
- [injection-demo.md](injection-demo.md): vulnerable vs parameterised queries in Python, Java and Node
- [mysql.sql](mysql.sql): users, roles and grants in MySQL

Next: [14 · Partitioning, replication and sharding](../14-partitioning-replication-sharding/)
