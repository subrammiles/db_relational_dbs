# 08 · Cursors

SQL works on **sets** of rows. A cursor lets procedural code process a result set **one row at a time**.

## Lifecycle

```
DECLARE  →  OPEN  →  FETCH (loop until no more rows)  →  CLOSE
```

| Kind | What it is |
|---|---|
| **Implicit cursor** | Created automatically for every SQL statement in PL/SQL. Attributes: `SQL%ROWCOUNT`, `SQL%FOUND`, `SQL%NOTFOUND` (PL/pgSQL: `FOUND`, `GET DIAGNOSTICS`) |
| **Explicit cursor** | You declare it with a query and control open/fetch/close yourself |
| **Cursor FOR loop** | Opens, fetches and closes for you; the most common form |
| **Parameterised cursor** | `CURSOR c (p_dept NUMBER) IS SELECT ... WHERE dept_id = p_dept` |
| **REF CURSOR / refcursor** | A cursor variable you can return from a procedure to the caller |
| **Server-side SQL cursor** | `DECLARE c CURSOR FOR ...; FETCH 100 FROM c;` (PostgreSQL), used to stream huge results in chunks |

### Explicit cursor attributes (Oracle)

| Attribute | Meaning |
|---|---|
| `c%ISOPEN` | Is the cursor open? |
| `c%FOUND` | Did the last fetch return a row? |
| `c%NOTFOUND` | Did the last fetch return nothing? (use to exit the loop) |
| `c%ROWCOUNT` | Rows fetched so far |

## When to use cursors (and when not)

Row-by-row processing is often called **RBAR** ("row by agonising row"). One set-based `UPDATE` touching 1 million rows is typically **orders of magnitude faster** than a cursor loop doing 1 million single-row updates.

Use a cursor only when:

- each row needs complex procedural logic or a call to something per row (send a message, call another procedure);
- you need to process a huge result in batches with commits in between;
- you're returning a result set from a procedure (REF CURSOR).

Otherwise write it as one SQL statement (`UPDATE ... FROM`, `MERGE`, `INSERT ... SELECT`, window functions). In Oracle, `BULK COLLECT` and `FORALL` give you array-based processing when you really need PL/SQL.

## Interview questions

1. **What is a cursor?** A pointer/handle over a query result that lets you fetch and process rows one at a time.
2. **Implicit vs explicit cursor?** Implicit: created automatically for each DML/SELECT INTO. Explicit: declared by you for multi-row queries, with OPEN/FETCH/CLOSE.
3. **Why avoid cursors?** They're slow compared with set-based SQL: many context switches and single-row operations.
4. **What is `%NOTFOUND`?** True when the last FETCH returned no row; the usual loop exit condition.
5. **What is a REF CURSOR?** A cursor variable that can be opened for different queries and passed back to a client.
6. **What are BULK COLLECT and FORALL?** Oracle features that fetch many rows into a collection and execute DML for many rows in one call, cutting PL/SQL ↔ SQL context switches.

## Files

- [examples.sql](examples.sql): PL/pgSQL cursors
- [oracle.sql](oracle.sql): PL/SQL explicit cursors, attributes, FOR loops, parameters, REF CURSOR, BULK COLLECT
- [mysql.sql](mysql.sql): MySQL cursor with a `NOT FOUND` handler

Next: [09 · Normalization](../09-normalization/)
