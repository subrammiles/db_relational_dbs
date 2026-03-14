CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    phone TEXT,
    email TEXT
);

INSERT INTO users (phone,email)
VALUES ('123456','test@gmail.com');