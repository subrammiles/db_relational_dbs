-- 09 · Exercises with solutions
--
-- A college keeps everything in one spreadsheet-like table:
--
--   enrolment_sheet(student_id, student_name, student_email, course_code, course_title,
--                   instructor_name, instructor_office, grade, phone_numbers)
--
-- Functional dependencies:
--   student_id      -> student_name, student_email
--   course_code     -> course_title, instructor_name
--   instructor_name -> instructor_office
--   (student_id, course_code) -> grade
--   phone_numbers holds a comma-separated list per student.
--
-- 1. Which normal forms does it violate, and why?
--    1NF: phone_numbers is not atomic (a list in one cell).
--    2NF: with key (student_id, course_code), student_* depend only on student_id and
--         course_title / instructor_name depend only on course_code (partial dependencies).
--    3NF: instructor_office depends on instructor_name, a non-key column (transitive dependency).
--
-- 2. Design the 3NF schema and migrate the data.

DROP TABLE IF EXISTS e_enrolments, e_student_phones, e_courses, e_instructors, e_students, enrolment_sheet;

CREATE TABLE enrolment_sheet (
    student_id INT, student_name TEXT, student_email TEXT,
    course_code TEXT, course_title TEXT,
    instructor_name TEXT, instructor_office TEXT,
    grade CHAR(1), phone_numbers TEXT
);

INSERT INTO enrolment_sheet VALUES
    (1, 'Ana', 'ana@uni.edu', 'DB101',  'Databases',  'Dr. Rao',  'B-204', 'A', '111, 222'),
    (1, 'Ana', 'ana@uni.edu', 'NET201', 'Networks',   'Dr. Shah', 'C-110', 'B', '111, 222'),
    (2, 'Ben', 'ben@uni.edu', 'DB101',  'Databases',  'Dr. Rao',  'B-204', 'C', '333'),
    (3, 'Cia', 'cia@uni.edu', 'ALG301', 'Algorithms', 'Dr. Rao',  'B-204', NULL, NULL);

-- Answer: five tables
CREATE TABLE e_students (
    student_id  INT PRIMARY KEY,
    name        TEXT NOT NULL,
    email       TEXT NOT NULL UNIQUE
);

CREATE TABLE e_student_phones (                     -- fixes 1NF
    student_id  INT  REFERENCES e_students (student_id),
    phone       TEXT,
    PRIMARY KEY (student_id, phone)
);

CREATE TABLE e_instructors (                        -- fixes 3NF
    instructor_id  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name           TEXT NOT NULL UNIQUE,
    office         TEXT
);

CREATE TABLE e_courses (                            -- fixes 2NF
    course_code    TEXT PRIMARY KEY,
    title          TEXT NOT NULL,
    instructor_id  INT REFERENCES e_instructors (instructor_id)
);

CREATE TABLE e_enrolments (                         -- only what depends on the whole key
    student_id   INT  REFERENCES e_students (student_id),
    course_code  TEXT REFERENCES e_courses (course_code),
    grade        CHAR(1) CHECK (grade IN ('A','B','C','D','F')),
    PRIMARY KEY (student_id, course_code)
);

INSERT INTO e_students SELECT DISTINCT student_id, student_name, student_email FROM enrolment_sheet;

INSERT INTO e_student_phones
SELECT DISTINCT student_id, TRIM(p)
FROM enrolment_sheet, unnest(string_to_array(phone_numbers, ',')) AS p
WHERE phone_numbers IS NOT NULL;

INSERT INTO e_instructors (name, office) SELECT DISTINCT instructor_name, instructor_office FROM enrolment_sheet;

INSERT INTO e_courses
SELECT DISTINCT s.course_code, s.course_title, i.instructor_id
FROM enrolment_sheet s JOIN e_instructors i ON i.name = s.instructor_name;

INSERT INTO e_enrolments SELECT student_id, course_code, grade FROM enrolment_sheet;

-- 3. Dr. Rao changes office. How many rows change before and after normalization?
SELECT COUNT(*) AS rows_to_update_before FROM enrolment_sheet WHERE instructor_name = 'Dr. Rao';   -- 3
UPDATE e_instructors SET office = 'D-001' WHERE name = 'Dr. Rao';                                   -- 1 row

-- 4. Rebuild the original sheet from the normalised tables (phones re-aggregated).
SELECT st.student_id, st.name, st.email, c.course_code, c.title, i.name AS instructor, i.office, e.grade,
       (SELECT STRING_AGG(phone, ', ' ORDER BY phone) FROM e_student_phones p WHERE p.student_id = st.student_id) AS phones
FROM e_enrolments e
JOIN e_students st   ON st.student_id   = e.student_id
JOIN e_courses c     ON c.course_code   = e.course_code
JOIN e_instructors i ON i.instructor_id = c.instructor_id
ORDER BY st.student_id, c.course_code;

DROP TABLE e_enrolments, e_student_phones, e_courses, e_instructors, e_students, enrolment_sheet;
