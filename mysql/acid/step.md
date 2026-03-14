Step 1: Create the Accounts Table

First we create a table that stores bank accounts.

CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    name VARCHAR(50),
    balance INT CHECK (balance >= 0)
);

Explanation:

account_id → unique account number

name → account holder

balance → money in the account

CHECK (balance >= 0) → prevents negative balances (Consistency rule)

How ACID Works in This Example
1️⃣ Atomicity (All or Nothing)

If something fails in the transaction:

START TRANSACTION;

UPDATE accounts
SET balance = balance - 1000
WHERE account_id = 1;

-- suppose this fails
UPDATE accounts
SET balance = balance + 1000
WHERE account_id = 99;

ROLLBACK;

Result:

account_id	name	balance
1	Alice	5000
2	Bob	2000

Nothing changed.

Both operations must succeed together.

2️⃣ Consistency (Rules Are Maintained)

We added a rule:

balance >= 0

If we try:

UPDATE accounts
SET balance = -500
WHERE account_id = 1;

MySQL rejects it.

So the database remains valid.

3️⃣ Isolation (Transactions Don't Interfere)

Imagine two people using the same account.

Transaction 1
START TRANSACTION;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 1;
Transaction 2
SELECT balance FROM accounts WHERE account_id = 1;

Transaction 2 will not see uncommitted changes.

This prevents errors like:

double spending

incorrect balances

4️⃣ Durability (Data Is Permanent)

After this command:

COMMIT;

The change is permanently stored on disk.

Even if:

database crashes

server restarts

power failure occurs

Balances remain:

| Alice | 4000 |
| Bob | 3000 |