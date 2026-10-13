-- 02 · Exercises with solutions
-- Try each one yourself before reading the solution below it.

-- 1. Create a table `books` with: an auto-generated id, a required title (up to 200 chars),
--    an ISBN that must be unique (13 chars), a price with 2 decimals, and a published date.
DROP TABLE IF EXISTS books;
CREATE TABLE books (
    book_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title      VARCHAR(200)  NOT NULL,
    isbn       CHAR(13)      UNIQUE,
    price      NUMERIC(8,2),
    published  DATE
);

-- 2. Create a table `it_staff` containing the first name, last name and salary
--    of everyone in department 1, in one statement.
DROP TABLE IF EXISTS it_staff;
CREATE TABLE it_staff AS
SELECT first_name, last_name, salary FROM employees WHERE dept_id = 1;

-- 3. Show the column names and types of `products` using information_schema.
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'products'
ORDER BY ordinal_position;

DROP TABLE books, it_staff;
