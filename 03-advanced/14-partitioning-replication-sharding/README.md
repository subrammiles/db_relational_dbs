# 14 · Partitioning, replication, sharding and scaling

These come up in senior and system-design interviews more than in day-to-day SQL.

## Partitioning (one server, one logical table split into pieces)

| Type | Split by | Typical key |
|---|---|---|
| **Range** | Value ranges | `order_date` by month/year |
| **List** | Explicit value lists | `country`, `region` |
| **Hash** | Hash of the key modulo N | `customer_id`, to spread load evenly |
| Composite | Range then hash, etc. | date + customer |

```sql
CREATE TABLE events (id BIGINT, created_at DATE NOT NULL, ...) PARTITION BY RANGE (created_at);
CREATE TABLE events_2025 PARTITION OF events FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

**Benefits**
- **Partition pruning:** `WHERE created_at >= '2025-06-01'` reads only the matching partitions.
- **Cheap data lifecycle:** dropping/detaching an old partition is instant, unlike `DELETE` of millions of rows.
- Smaller per-partition indexes; maintenance (vacuum, reindex) per partition.

**Costs**
- Queries that don't filter on the partition key scan **every** partition.
- Primary keys/unique constraints must include the partition key (PostgreSQL, MySQL).
- Too many partitions slow planning. Thousands is too many; dozens to hundreds is typical.

Partition when a table is very large (hundreds of GB / billions of rows) **and** queries or retention follow the key. It's not a substitute for indexes.

| Database | Support |
|---|---|
| PostgreSQL 10+ | Declarative `PARTITION BY RANGE / LIST / HASH` |
| MySQL | `PARTITION BY RANGE / LIST / HASH / KEY` (no foreign keys on partitioned tables) |
| Oracle | Range, list, hash, interval (auto-creates partitions), reference partitioning (separately licensed option) |
| SQL Server | Partition functions + partition schemes |

**Vertical partitioning** splits **columns**: move rarely used or large columns (a `bio TEXT`, a blob) into a 1:1 side table so the hot table stays narrow.

## Replication (copies of the whole database on several servers)

```
            writes                 WAL / binlog stream
  app ───────────▶ Primary ─────────────────────────────▶ Replica 1  ◀── read queries
                       └────────────────────────────────▶ Replica 2  ◀── read queries
```

| Kind | How | Trade-off |
|---|---|---|
| **Asynchronous** | Primary commits, then ships changes | Fast; replica can lag; a failover can lose the last few transactions |
| **Synchronous** | Primary waits for a replica to confirm | No data loss on failover; higher write latency |
| **Physical / streaming** (PG WAL, Oracle Data Guard) | Copies byte-level changes | Exact copy of the whole cluster |
| **Logical** (PG logical replication, MySQL binlog row format) | Copies row changes per table | Selective tables, cross-version upgrades, CDC |
| Multi-primary | Several writable nodes | Conflict resolution needed (Galera, Group Replication, Oracle RAC is shared-disk) |

Uses: **high availability** (failover), **read scaling** (send reports and read-only traffic to replicas), backups and analytics off the primary.
Watch for **replication lag**: a user writes, then reads from a replica and doesn't see their change ("read-your-writes"). Route those reads to the primary.

## Sharding (horizontal scaling across servers)

Each shard is an independent database holding **a subset of the rows**: e.g. customers 1–1M on shard A, 1M–2M on shard B, or `hash(customer_id) % 8`.

| Strategy | Pro | Con |
|---|---|---|
| Range | Simple, range scans stay local | Hot spots (all new users on the last shard) |
| Hash | Even distribution | Range queries hit every shard; resharding moves data (consistent hashing helps) |
| Directory / lookup | Flexible placement | Lookup service is another component |
| Geographic / tenant | Data locality, compliance | Uneven shard sizes |

**Costs of sharding:** cross-shard joins and transactions are hard (two-phase commit or avoided entirely), global unique IDs need a scheme (UUIDs, Snowflake IDs), rebalancing is operationally heavy, and every query should include the shard key.

Shard **last**: after indexing, query tuning, caching, read replicas, partitioning and vertical scaling are exhausted. Tools: Citus (PostgreSQL), Vitess (MySQL), Oracle Sharding, or distributed SQL databases (CockroachDB, YugabyteDB, Spanner, TiDB).

## CAP and consistency (in one paragraph)

In a distributed system that experiences a network **P**artition, you must choose between **C**onsistency (every read sees the latest write) and **A**vailability (every request gets an answer). A single-node RDBMS is "CA" by definition; replicated setups pick per configuration (synchronous replication leans to C, async to A). **PACELC** adds: even without partitions, you trade **L**atency against **C**onsistency.

## Backups and recovery

| | What | Restore |
|---|---|---|
| Logical backup | `pg_dump`, `mysqldump`, Oracle Data Pump | Portable, slow for big DBs |
| Physical backup | `pg_basebackup`, Percona XtraBackup, RMAN | Fast, same version/platform |
| Point-in-time recovery (PITR) | Base backup + archived WAL/binlogs/redo | Restore to any second, e.g. just before an accidental `DELETE` |

Know your **RPO** (how much data you can lose) and **RTO** (how long recovery may take), and **test restores** regularly.

## Interview questions

1. **Partitioning vs sharding?** Partitioning splits a table within one database server; sharding spreads rows across multiple independent servers.
2. **What is partition pruning?** The planner skips partitions that can't contain matching rows, based on the WHERE clause.
3. **Replication vs sharding?** Replication copies all data to several nodes (availability, read scaling); sharding splits data so each node holds part of it (write and storage scaling).
4. **Sync vs async replication?** Sync waits for replica acknowledgement (no loss, slower writes); async doesn't (fast, possible loss and lag).
5. **What is replication lag and how do you handle it?** Delay before a replica reflects primary writes; route read-after-write to primary, monitor lag, use sync replication where needed.
6. **How do you choose a shard key?** High cardinality, even distribution, present in most queries, and keeps related data together (e.g. tenant_id).
7. **How would you scale a database that's too slow?** Measure first; then indexes and query fixes → caching → read replicas → partitioning → bigger hardware → sharding.
8. **Vertical vs horizontal scaling?** Bigger machine vs more machines.
9. **What are RPO and RTO?** Max acceptable data loss and max acceptable downtime.

## Files

- [examples.sql](examples.sql): range, list and hash partitioning with pruning in PostgreSQL
- [exercises.sql](exercises.sql)

Next: [15 · JSON](../15-json/)
