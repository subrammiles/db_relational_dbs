use mydatabase;


CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    name VARCHAR(50),
    balance INT CHECK (balance >= 0)
);


INSERT INTO accounts (account_id, name, balance)
VALUES 
(1, 'Alice', 5000),
(2, 'Bob', 2000);


 

START TRANSACTION;

UPDATE accounts
SET balance = balance - 1000
WHERE account_id = 1;

UPDATE accounts
SET balance = balance + 1000
WHERE account_id = 2;

COMMIT;



SELECT * from accounts