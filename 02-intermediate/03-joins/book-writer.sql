-- 03 · Joins: the book / writer example from README.md (PostgreSQL)
-- Book 4 has no writer; writer 100 has no book.

DROP TABLE IF EXISTS book;
DROP TABLE IF EXISTS writer;

CREATE TABLE writer (
    writer_id  INT          NOT NULL,
    full_name  VARCHAR(20)  NOT NULL,
    PRIMARY KEY (writer_id)
);

CREATE TABLE book (
    book_id     INT          NOT NULL,
    book_title  VARCHAR(50)  NOT NULL,
    writer_id   INT,
    PRIMARY KEY (book_id)
);

INSERT INTO writer (writer_id, full_name) VALUES
    (100, 'R D S Shamaji'),
    (250, 'JK Rowling'),
    (323, 'Subrahmanyam P'),
    (444, 'Albert Newton'),
    (500, 'Xyortman Henry');

INSERT INTO book (book_id, book_title, writer_id) VALUES
    (1, 'Harry Potter',      250),
    (2, 'Modern Physics',    444),
    (3, 'Engineering Maths', 323),
    (4, 'The Bible',         NULL),
    (5, 'Learn German',      500);

-- INNER JOIN: 4 rows (no Bible, no Shamaji)
SELECT * FROM book b INNER JOIN writer w ON w.writer_id = b.writer_id ORDER BY b.book_id;

-- LEFT JOIN, book on the left: 5 rows, The Bible has NULL writer columns
SELECT * FROM book b LEFT JOIN writer w ON w.writer_id = b.writer_id ORDER BY b.book_id;

-- LEFT JOIN, writer on the left: 5 rows, Shamaji has NULL book columns
SELECT * FROM writer w LEFT JOIN book b ON w.writer_id = b.writer_id ORDER BY w.writer_id;

-- RIGHT JOIN, writer on the right: same rows as the query above, columns in book-first order
SELECT * FROM book b RIGHT JOIN writer w ON w.writer_id = b.writer_id ORDER BY w.writer_id;

-- FULL OUTER JOIN: 6 rows, both unmatched rows present
SELECT * FROM book b FULL OUTER JOIN writer w ON w.writer_id = b.writer_id ORDER BY b.book_id;

-- NATURAL JOIN: joins on writer_id (the only common column), which appears once
SELECT * FROM writer NATURAL JOIN book ORDER BY book_id;

-- USING: same result as NATURAL JOIN here, but explicit about the column
SELECT * FROM writer JOIN book USING (writer_id) ORDER BY book_id;

-- Anti-join: writers with no book
SELECT w.full_name FROM writer w LEFT JOIN book b ON b.writer_id = w.writer_id WHERE b.book_id IS NULL;

DROP TABLE book;
DROP TABLE writer;
