# Oracle setup (Docker)

Oracle Database is only officially supported on a few operating systems. Ubuntu is not one of them, so the easiest route on Ubuntu is the official Oracle XE (Express Edition) container.

| Operating system | Support |
|---|---|
| Oracle Linux 7 / 8 / 9 | Best: Oracle's own distro, most tested |
| Red Hat Enterprise Linux | Fully supported |
| SUSE Linux Enterprise | Supported |
| Windows Server | Supported |
| Solaris | Supported, less common |
| Ubuntu | Not officially supported → use Docker |

## 1. Pull and run Oracle XE

```bash
docker pull container-registry.oracle.com/database/express:21.3.0-xe

docker run -d \
  --name oracle-xe \
  -p 1521:1521 \
  -p 5500:5500 \
  -e ORACLE_PWD=Oracle123 \
  container-registry.oracle.com/database/express:21.3.0-xe
```

| Setting | Meaning |
|---|---|
| `1521` | Database listener port |
| `5500` | EM Express web UI |
| `ORACLE_PWD` | Password for `SYS`, `SYSTEM` and `PDBADMIN` |
| `oracle-xe` | Container name |

The first start takes several minutes. Wait until `docker logs -f oracle-xe` prints `DATABASE IS READY TO USE!`.

## 2. Connect with SQL*Plus

```bash
docker exec -it oracle-xe bash
sqlplus sys/Oracle123@//localhost:1521/XEPDB1 as sysdba
```

## 3. Use the pluggable database

Oracle 12c+ is multitenant: a container database (CDB) holds pluggable databases (PDBs). XE ships with one PDB called `XEPDB1`. Create your objects there, not in the root container.

```sql
ALTER SESSION SET CONTAINER = XEPDB1;
SHOW CON_NAME;          -- XEPDB1
```

## 4. Create a user (in Oracle a user *is* a schema)

```sql
CREATE USER appuser IDENTIFIED BY apppass;
GRANT CONNECT, RESOURCE, CREATE VIEW TO appuser;
ALTER USER appuser QUOTA UNLIMITED ON USERS;
```

Reconnect as that user:

```bash
sqlplus appuser/apppass@//localhost:1521/XEPDB1
```

## 5. Useful dictionary queries

```sql
SELECT name FROM v$database;          -- database name (needs DBA privileges)
DESCRIBE v$database;
SELECT table_name FROM user_tables;   -- tables you own
SELECT view_name  FROM user_views;
SELECT * FROM dual;                   -- one-row dummy table, e.g. SELECT SYSDATE FROM dual;
```

## Oracle habits to know

- Every `SELECT` needs a `FROM`; use `dual` for expressions: `SELECT 1 + 1 FROM dual;`
- DML is not auto-committed in SQL*Plus. Run `COMMIT;` or your changes vanish when you disconnect.
- Empty string `''` **is** `NULL` in Oracle.
- Inserting several rows: `INSERT ALL INTO t (...) VALUES (...) INTO t (...) VALUES (...) SELECT * FROM dual;` (23c also accepts multi-row `VALUES`).
- `SET SERVEROUTPUT ON` before running PL/SQL that calls `dbms_output.put_line`.

See [sample-db/README.md](../sample-db/README.md) for how to adapt the sample schema to Oracle types.
