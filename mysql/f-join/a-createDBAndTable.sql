CREATE DATABASE joinDB;

GRANT ALL PRIVILEGES ON joinDB.* TO 'testuser1'@'localhost';

USE joinDB;


CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50),
    city VARCHAR(50)
);


CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    product VARCHAR(50),
    amount INT
);


INSERT INTO customers (name, city) VALUES
('Alice', 'Bangalore'),
('Bob', 'Delhi'),
('Charlie', 'Mumbai'),
('David', 'Chennai');



INSERT INTO orders (customer_id, product, amount) VALUES
(1, 'Laptop', 70000),
(1, 'Mouse', 500),
(2, 'Phone', 30000),
(3, 'Tablet', 20000);