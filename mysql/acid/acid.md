ACID describes the four properties that guarantee reliable database transactions. A transaction is a group of SQL operations that should behave as a single logical unit of work.

ACID stands for:

A – Atomicity

C – Consistency

I – Isolation

D – Durability

Atomicity (All or Nothing)

Atomicity means a transaction either completes fully or not at all.

If one operation fails, the entire transaction is rolled back.

Consistency (Data Always Valid)

Consistency ensures the database moves from one valid state to another valid state.

Isolation (Transactions Do Not Interfere)

Isolation means multiple transactions running at the same time do not affect each other.

Each transaction behaves as if it is running alone.
Durability (Data Is Permanently Saved)

Once a transaction is committed, the data is permanently stored, even if the system crashes.