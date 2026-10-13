-- =====================================================================
-- Worked schema-design answer: a library system (PostgreSQL)
-- See schema-design.md for the requirements and reasoning.
-- Everything lives in its own schema "lib".
-- =====================================================================

SET client_min_messages = warning;
DROP SCHEMA IF EXISTS lib CASCADE;
RESET client_min_messages;
CREATE SCHEMA lib;

-- ---------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------
CREATE TABLE lib.categories (
    category_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE lib.books (                        -- a title
    book_id       INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    isbn          CHAR(13)     NOT NULL UNIQUE,
    title         VARCHAR(200) NOT NULL,
    category_id   INT          REFERENCES lib.categories (category_id),
    published     INT          CHECK (published BETWEEN 1450 AND 2100)
);

CREATE TABLE lib.authors (
    author_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(100) NOT NULL
);

CREATE TABLE lib.book_authors (                 -- M:N junction
    book_id    INT NOT NULL REFERENCES lib.books (book_id) ON DELETE CASCADE,
    author_id  INT NOT NULL REFERENCES lib.authors (author_id),
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE lib.copies (                       -- a physical item
    copy_id    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_id    INT NOT NULL REFERENCES lib.books (book_id),
    barcode    VARCHAR(20) NOT NULL UNIQUE,
    condition  VARCHAR(10) NOT NULL DEFAULT 'good' CHECK (condition IN ('new', 'good', 'worn', 'lost'))
);

CREATE TABLE lib.members (
    member_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(100) NOT NULL UNIQUE,
    joined_on  DATE NOT NULL DEFAULT CURRENT_DATE,
    status     VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'left'))
);

CREATE TABLE lib.loans (
    loan_id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    copy_id      INT  NOT NULL REFERENCES lib.copies (copy_id),
    member_id    INT  NOT NULL REFERENCES lib.members (member_id),
    borrowed_at  DATE NOT NULL DEFAULT CURRENT_DATE,
    due_at       DATE NOT NULL,
    returned_at  DATE,
    CHECK (due_at > borrowed_at),
    CHECK (returned_at IS NULL OR returned_at >= borrowed_at)
);
-- Business rule enforced by the database: a copy can only be on one active loan
CREATE UNIQUE INDEX one_active_loan_per_copy ON lib.loans (copy_id) WHERE returned_at IS NULL;

CREATE TABLE lib.fines (
    fine_id   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    loan_id   INT NOT NULL UNIQUE REFERENCES lib.loans (loan_id),    -- 0..1 fine per loan
    amount    NUMERIC(8,2) NOT NULL CHECK (amount > 0),
    paid_at   DATE
);

CREATE TABLE lib.reservations (
    reservation_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    book_id         INT NOT NULL REFERENCES lib.books (book_id),
    member_id       INT NOT NULL REFERENCES lib.members (member_id),
    reserved_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    fulfilled_at    TIMESTAMPTZ
);
-- A member can hold only one open reservation per title
CREATE UNIQUE INDEX one_open_reservation ON lib.reservations (book_id, member_id) WHERE fulfilled_at IS NULL;

-- Indexes on foreign keys and for the main queries
CREATE INDEX ON lib.books (category_id);
CREATE INDEX ON lib.book_authors (author_id);
CREATE INDEX ON lib.copies (book_id);
CREATE INDEX ON lib.loans (member_id);
CREATE INDEX loans_open_due ON lib.loans (due_at) WHERE returned_at IS NULL;   -- overdue job
CREATE INDEX ON lib.reservations (book_id, reserved_at) WHERE fulfilled_at IS NULL;

-- ---------------------------------------------------------------------
-- Business logic: borrowing and returning
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE lib.borrow(p_member INT, p_copy INT, p_on DATE DEFAULT CURRENT_DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status  TEXT;
    v_active  INT;
BEGIN
    -- Lock the member row so two concurrent borrows can't both pass the limit check
    SELECT status INTO v_status FROM lib.members WHERE member_id = p_member FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'No member %', p_member;
    END IF;
    IF v_status <> 'active' THEN
        RAISE EXCEPTION 'Member % is %', p_member, v_status;
    END IF;

    SELECT COUNT(*) INTO v_active FROM lib.loans WHERE member_id = p_member AND returned_at IS NULL;
    IF v_active >= 5 THEN
        RAISE EXCEPTION 'Member % already has % active loans', p_member, v_active;
    END IF;

    -- The partial unique index rejects the insert if the copy is already lent out
    INSERT INTO lib.loans (copy_id, member_id, borrowed_at, due_at)
    VALUES (p_copy, p_member, p_on, p_on + 14);
END;
$$;

CREATE OR REPLACE PROCEDURE lib.return_copy(p_copy INT, p_on DATE DEFAULT CURRENT_DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    v_loan  lib.loans%ROWTYPE;
BEGIN
    UPDATE lib.loans SET returned_at = p_on
    WHERE copy_id = p_copy AND returned_at IS NULL
    RETURNING * INTO v_loan;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Copy % is not on loan', p_copy;
    END IF;

    IF p_on > v_loan.due_at THEN
        INSERT INTO lib.fines (loan_id, amount) VALUES (v_loan.loan_id, (p_on - v_loan.due_at) * 10);
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- Sample data
-- ---------------------------------------------------------------------
INSERT INTO lib.categories (name) VALUES ('Databases'), ('Fiction'), ('Science');

INSERT INTO lib.books (isbn, title, category_id, published) VALUES
    ('9780000000001', 'SQL Fundamentals',       1, 2019),
    ('9780000000002', 'Designing Data Systems', 1, 2017),
    ('9780000000003', 'The Silent Library',     2, 2021),
    ('9780000000004', 'A Short History of Time',3, 1998);

INSERT INTO lib.authors (name) VALUES ('R. Kumar'), ('M. Klein'), ('A. Sen'), ('L. Hart');
INSERT INTO lib.book_authors VALUES (1, 1), (2, 2), (2, 1), (3, 3), (4, 4);

INSERT INTO lib.copies (book_id, barcode) VALUES
    (1, 'C-0001'), (1, 'C-0002'), (2, 'C-0003'), (3, 'C-0004'), (3, 'C-0005'), (4, 'C-0006');

INSERT INTO lib.members (name, email, joined_on) VALUES
    ('Ana', 'ana@mail.com', '2025-01-01'),
    ('Ben', 'ben@mail.com', '2025-02-01'),
    ('Cia', 'cia@mail.com', '2025-03-01');

CALL lib.borrow(1, 1, '2026-01-02');     -- Ana: SQL Fundamentals copy 1
CALL lib.borrow(1, 3, '2026-01-02');     -- Ana: Designing Data Systems (only copy)
CALL lib.borrow(2, 2, '2026-01-10');     -- Ben: SQL Fundamentals copy 2
CALL lib.borrow(3, 4, '2026-01-12');     -- Cia: The Silent Library
CALL lib.return_copy(1, '2026-01-20');   -- Ana returns copy 1 four days late (due 01-16) → fine of 40
CALL lib.borrow(2, 1, '2026-01-21');     -- Ben borrows copy 1 after Ana returned it

INSERT INTO lib.reservations (book_id, member_id, reserved_at) VALUES
    (2, 3, '2026-01-15 10:00+00'),       -- Cia waits for Designing Data Systems
    (2, 2, '2026-01-16 09:00+00');       -- then Ben

-- The rules hold: each of these is rejected
DO $$
BEGIN
    BEGIN
        CALL lib.borrow(3, 3, '2026-01-22');          -- copy 3 is still with Ana
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'Rejected: copy already on loan';
    END;
    BEGIN
        INSERT INTO lib.reservations (book_id, member_id) VALUES (2, 3);   -- Cia already queued
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'Rejected: duplicate open reservation';
    END;
END $$;

-- ---------------------------------------------------------------------
-- The queries the design must answer
-- ---------------------------------------------------------------------

-- 1. Availability per title
SELECT b.title,
       COUNT(c.copy_id)                                    AS copies,
       COUNT(c.copy_id) - COUNT(l.loan_id)                 AS available
FROM lib.books b
JOIN lib.copies c     ON c.book_id = b.book_id AND c.condition <> 'lost'
LEFT JOIN lib.loans l ON l.copy_id = c.copy_id AND l.returned_at IS NULL
GROUP BY b.book_id, b.title
ORDER BY b.title;

-- 2. Overdue loans on 2026-02-01, with the fine accrued so far
SELECT m.name, b.title, l.due_at, DATE '2026-02-01' - l.due_at AS days_late,
       (DATE '2026-02-01' - l.due_at) * 10 AS fine_so_far
FROM lib.loans l
JOIN lib.members m ON m.member_id = l.member_id
JOIN lib.copies c  ON c.copy_id   = l.copy_id
JOIN lib.books b   ON b.book_id   = c.book_id
WHERE l.returned_at IS NULL AND l.due_at < DATE '2026-02-01'
ORDER BY days_late DESC;

-- 3. A member's borrowing history with authors and fines
SELECT b.title,
       STRING_AGG(a.name, ', ' ORDER BY a.name) AS authors,
       l.borrowed_at, l.returned_at, f.amount AS fine
FROM lib.loans l
JOIN lib.copies c       ON c.copy_id = l.copy_id
JOIN lib.books b        ON b.book_id = c.book_id
JOIN lib.book_authors ba ON ba.book_id = b.book_id
JOIN lib.authors a      ON a.author_id = ba.author_id
LEFT JOIN lib.fines f   ON f.loan_id = l.loan_id
WHERE l.member_id = 1
GROUP BY l.loan_id, b.title, l.borrowed_at, l.returned_at, f.amount
ORDER BY l.borrowed_at;

-- 4. Most borrowed titles
SELECT b.title, COUNT(*) AS times_borrowed
FROM lib.loans l
JOIN lib.copies c ON c.copy_id = l.copy_id
JOIN lib.books b  ON b.book_id = c.book_id
GROUP BY b.book_id, b.title
ORDER BY times_borrowed DESC, b.title
LIMIT 3;

-- 5. Who is next in the queue for 'Designing Data Systems'?
SELECT m.name, r.reserved_at
FROM lib.reservations r
JOIN lib.members m ON m.member_id = r.member_id
WHERE r.book_id = 2 AND r.fulfilled_at IS NULL
ORDER BY r.reserved_at
LIMIT 1;

-- 6. Members with unpaid fines
SELECT m.name, SUM(f.amount) AS owed
FROM lib.fines f
JOIN lib.loans l   ON l.loan_id = f.loan_id
JOIN lib.members m ON m.member_id = l.member_id
WHERE f.paid_at IS NULL
GROUP BY m.member_id, m.name;

SET client_min_messages = warning;
DROP SCHEMA lib CASCADE;
