CREATE DATABASE testDB;

use testDB;

CREATE TABLE users(
    user_id INT(50)  NOT NULL AUTO_INCREMENT,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(60) NOT NULL,
    PRIMARY KEY(user_id)
);

INSERT INTO users (phone,email)
VALUES ('123456','test@gmail.com');


To inset many rows

INSERT INTO users (phone, email)
VALUES 
('123456', 'test1@gmail.com'),
('987654', 'test2@gmail.com'),
('555666', 'test3@gmail.com'),
('777888', 'test4@gmail.com');