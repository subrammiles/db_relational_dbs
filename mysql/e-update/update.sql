CREATE DATABASE testDB;

GRANT ALL PRIVILEGES ON testDB.* TO 'testuser1'@'localhost';

use testDB;

CREATE TABLE users(
    user_id INT(50)  NOT NULL AUTO_INCREMENT,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(60) NOT NULL,
    PRIMARY KEY(user_id)
);

INSERT INTO users (phone,email)
VALUES ('123456','test@gmail.com');

UPDATE users
SET email = 'updated@gmail.com'
WHERE phone = '123456';