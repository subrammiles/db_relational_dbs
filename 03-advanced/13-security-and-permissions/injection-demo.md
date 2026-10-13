# SQL injection: vulnerable vs safe code

The fix is the same in every language: **send the SQL text and the values separately** (parameterised query / prepared statement). Never build SQL by concatenating or formatting user input into the string.

Attack input used below: `email = "x' OR '1'='1"`.

## Python (psycopg / DB-API)

```python
# VULNERABLE: the input becomes part of the SQL
cur.execute(f"SELECT * FROM customers WHERE email = '{email}'")
#  → SELECT * FROM customers WHERE email = 'x' OR '1'='1'   (returns every row)

# SAFE: %s is a placeholder, the driver sends the value separately
cur.execute("SELECT * FROM customers WHERE email = %s", (email,))

# Identifiers can't be parameters: use psycopg's sql module (or an allow-list)
from psycopg import sql
cur.execute(sql.SQL("SELECT * FROM customers ORDER BY {}").format(sql.Identifier(sort_col)))
```

## Java (JDBC)

```java
// VULNERABLE
Statement st = conn.createStatement();
ResultSet rs = st.executeQuery("SELECT * FROM customers WHERE email = '" + email + "'");

// SAFE
PreparedStatement ps = conn.prepareStatement("SELECT * FROM customers WHERE email = ?");
ps.setString(1, email);
ResultSet rs = ps.executeQuery();
```

## Node.js (node-postgres)

```js
// VULNERABLE
await client.query(`SELECT * FROM customers WHERE email = '${email}'`);

// SAFE
await client.query('SELECT * FROM customers WHERE email = $1', [email]);
```

## Classic payloads (so you recognise them in logs)

| Input | Effect when concatenated |
|---|---|
| `' OR '1'='1` | Condition always true: bypass login, dump rows |
| `'; DROP TABLE customers; --` | Stacked query (works where the driver allows multiple statements) |
| `' UNION SELECT username, password FROM users --` | Reads another table through the same result |
| `' AND SLEEP(5) --` | Blind injection: infers data from response time |

## Why escaping by hand isn't enough

Character sets, backslash handling (MySQL), numeric contexts without quotes (`WHERE id = ` + input), `LIKE` wildcards and identifiers all have different rules. Parameterisation avoids the whole problem because the value is never parsed as SQL.
