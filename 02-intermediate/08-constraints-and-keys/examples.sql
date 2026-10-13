-- 08 · Constraints and keys (PostgreSQL)
-- Statements that are meant to fail are wrapped in DO blocks that catch the
-- error and print it, so the whole file runs top to bottom.

DROP TABLE IF EXISTS enrolments;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;

CREATE TABLE students (
    student_id  INT GENERATED ALWAYS AS IDENTITY,
    email       VARCHAR(100) NOT NULL,
    full_name   VARCHAR(100) NOT NULL,
    birth_date  DATE,
    CONSTRAINT students_pk          PRIMARY KEY (student_id),
    CONSTRAINT students_email_uq    UNIQUE (email),
    CONSTRAINT students_birth_chk   CHECK (birth_date > DATE '1900-01-01')
);

CREATE TABLE courses (
    course_id   INT PRIMARY KEY,
    title       VARCHAR(100) NOT NULL,
    max_seats   INT NOT NULL DEFAULT 30 CHECK (max_seats BETWEEN 1 AND 500)
);

CREATE TABLE enrolments (
    student_id  INT NOT NULL,
    course_id   INT NOT NULL,
    grade       CHAR(1),
    enrolled_on DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT enrolments_pk         PRIMARY KEY (student_id, course_id),
    CONSTRAINT enrolments_grade_chk  CHECK (grade IN ('A', 'B', 'C', 'D', 'F')),
    CONSTRAINT enrolments_student_fk FOREIGN KEY (student_id)
        REFERENCES students (student_id) ON DELETE CASCADE,
    CONSTRAINT enrolments_course_fk  FOREIGN KEY (course_id)
        REFERENCES courses (course_id)   ON DELETE RESTRICT
);
-- Index the FK columns that aren't the leading column of the PK
CREATE INDEX enrolments_course_idx ON enrolments (course_id);

INSERT INTO students (email, full_name, birth_date) VALUES
    ('ana@uni.edu', 'Ana', '2003-04-01'),
    ('ben@uni.edu', 'Ben', '2002-09-15');
INSERT INTO courses (course_id, title) VALUES (101, 'Databases'), (102, 'Networks');
INSERT INTO enrolments (student_id, course_id, grade) VALUES (1, 101, 'A'), (1, 102, NULL), (2, 101, 'B');

-- Each of these violates a constraint. The DO block prints the error instead of stopping.
DO $$
DECLARE
    stmts TEXT[] := ARRAY[
        $q$INSERT INTO students (email, full_name) VALUES ('ana@uni.edu', 'Ana Again')$q$,        -- UNIQUE
        $q$INSERT INTO students (email, full_name) VALUES (NULL, 'No Email')$q$,                  -- NOT NULL
        $q$INSERT INTO students (email, full_name, birth_date) VALUES ('x@uni.edu', 'X', '1800-01-01')$q$, -- CHECK
        $q$INSERT INTO enrolments (student_id, course_id) VALUES (1, 101)$q$,                      -- PRIMARY KEY
        $q$INSERT INTO enrolments (student_id, course_id) VALUES (1, 999)$q$,                      -- FOREIGN KEY
        $q$INSERT INTO enrolments (student_id, course_id, grade) VALUES (2, 102, 'Z')$q$,          -- CHECK
        $q$DELETE FROM courses WHERE course_id = 101$q$                                            -- ON DELETE RESTRICT
    ];
    s TEXT;
BEGIN
    FOREACH s IN ARRAY stmts LOOP
        BEGIN
            EXECUTE s;
            RAISE NOTICE 'unexpectedly succeeded: %', s;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '% -> %', SQLSTATE, SQLERRM;
        END;
    END LOOP;
END $$;

-- ON DELETE CASCADE: deleting student 1 removes their 2 enrolments too
SELECT COUNT(*) AS enrolments_before FROM enrolments;
DELETE FROM students WHERE student_id = 1;
SELECT COUNT(*) AS enrolments_after FROM enrolments;

-- UNIQUE allows multiple NULLs
CREATE TEMP TABLE phones (phone VARCHAR(20) UNIQUE);
INSERT INTO phones VALUES (NULL), (NULL);
SELECT COUNT(*) AS null_phones FROM phones;   -- 2

-- A CHECK passes when the condition is NULL
CREATE TEMP TABLE prices (price NUMERIC CHECK (price > 0));
INSERT INTO prices VALUES (NULL);             -- accepted!

-- Adding / dropping constraints later
ALTER TABLE courses ADD CONSTRAINT courses_title_uq UNIQUE (title);
ALTER TABLE courses DROP CONSTRAINT courses_title_uq;

-- See every constraint on a table
SELECT conname, contype, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'enrolments'::regclass;

-- Same via the standard information_schema
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'employees';

DROP TABLE enrolments, students, courses;
