# PostgreSQL setup (Ubuntu)

## 1. Install

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl status postgresql      # should show: active (running)
```

## 2. Switch to the `postgres` system user

Installing PostgreSQL creates a Linux user called `postgres` that owns the server. Switch to it and open the shell:

```bash
sudo -i -u postgres
psql
```

The prompt looks like `postgres=#`. `\q` quits.

## 3. Create a database and a user

```sql
CREATE DATABASE sqltutorial;
CREATE USER testuser WITH PASSWORD 'mypassword';
GRANT ALL PRIVILEGES ON DATABASE sqltutorial TO testuser;

-- PostgreSQL 15+: the public schema is no longer writable by everyone
\c sqltutorial
GRANT ALL ON SCHEMA public TO testuser;
```

Connect as the new user from your normal account:

```bash
psql -h localhost -U testuser -d sqltutorial
```

## 4. Load the sample database

```bash
psql -h localhost -U testuser -d sqltutorial -f sample-db/schema.sql
psql -h localhost -U testuser -d sqltutorial -f sample-db/seed.sql
```

## Alternative: Docker

```bash
docker run -d --name sqltutorial-pg -e POSTGRES_PASSWORD=pg -p 5432:5432 postgres:16
export PGHOST=localhost PGUSER=postgres PGPASSWORD=pg PGDATABASE=postgres
```

## psql cheat sheet

| Command | Does |
|---|---|
| `\l` | List databases |
| `\c dbname` | Connect to another database |
| `\dt` | List tables |
| `\d table` | Describe a table (columns, indexes, constraints) |
| `\df` | List functions |
| `\dv` | List views |
| `\x` | Toggle expanded (vertical) output |
| `\timing` | Show how long each query takes |
| `\i file.sql` | Run a file |
| `\e` | Edit the last query in your editor |
| `\q` | Quit |
