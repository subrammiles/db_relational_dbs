-- 03 · Views in Oracle
-- (The user needs the CREATE VIEW privilege; CREATE MATERIALIZED VIEW for the last part.)

CREATE TABLE users (
    id       NUMBER(10)    NOT NULL,
    name     VARCHAR2(40)  NOT NULL,
    country  VARCHAR2(10),
    PRIMARY KEY (id)
);

INSERT ALL
    INTO users (id, name, country) VALUES (1,  'James G',  'USA')
    INTO users (id, name, country) VALUES (2,  'Jack',     'USA')
    INTO users (id, name, country) VALUES (3,  'Samantha', 'USA')
    INTO users (id, name, country) VALUES (4,  'Rose',     'USA')
    INTO users (id, name, country) VALUES (5,  'Ram',      'India')
    INTO users (id, name, country) VALUES (6,  'Sita',     'India')
    INTO users (id, name, country) VALUES (7,  'Chan Che', 'China')
    INTO users (id, name, country) VALUES (8,  'Shalok',   'UK')
    INTO users (id, name, country) VALUES (9,  'Kinergan', 'Germany')
    INTO users (id, name, country) VALUES (10, 'GutanTag', 'Germany')
SELECT * FROM dual;
COMMIT;

-- A view exposing only the country column
CREATE VIEW user_country_view AS SELECT country FROM users;
SELECT * FROM user_country_view;

-- A view with all columns
CREATE VIEW user_view AS SELECT * FROM users;
SELECT * FROM user_view;

-- Read-only view: no DML allowed through it
CREATE OR REPLACE VIEW india_users AS
SELECT id, name FROM users WHERE country = 'India'
WITH READ ONLY;

-- View with CHECK OPTION: can't insert a non-German user through it
CREATE OR REPLACE VIEW german_users AS
SELECT id, name, country FROM users WHERE country = 'Germany'
WITH CHECK OPTION;
-- INSERT INTO german_users VALUES (11, 'Pierre', 'France');   -- ORA-01402: view WITH CHECK OPTION where-clause violation

-- List your views and their SQL
SELECT view_name, text FROM user_views;

-- Materialized view refreshed on demand
CREATE MATERIALIZED VIEW users_per_country
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS SELECT country, COUNT(*) AS users FROM users GROUP BY country;

SELECT * FROM users_per_country;
EXEC DBMS_MVIEW.REFRESH('USERS_PER_COUNTRY');

-- Drop
DROP MATERIALIZED VIEW users_per_country;
DROP VIEW german_users;
DROP VIEW india_users;
DROP VIEW user_view;
DROP VIEW user_country_view;
DROP TABLE users;
