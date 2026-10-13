-- 02 · GROUP BY and HAVING in Oracle
--
-- GROUP BY collects data from multiple rows and groups the result by one or more
-- columns. It's used with aggregate functions: SUM, COUNT, MAX, MIN, AVG.

-- ---------------------------------------------------------------
-- Example 1: total sales per item
-- ---------------------------------------------------------------
CREATE TABLE sales (
    item        VARCHAR2(20)  NOT NULL,
    sale_count  NUMBER(15)    NOT NULL,
    country     VARCHAR2(20),
    PRIMARY KEY (country)
);

INSERT ALL
    INTO sales (item, sale_count, country) VALUES ('cap',      100, 'USA')
    INTO sales (item, sale_count, country) VALUES ('cap',      400, 'China')
    INTO sales (item, sale_count, country) VALUES ('cap',       50, 'India')
    INTO sales (item, sale_count, country) VALUES ('Shoes',    200, 'Germany')
    INTO sales (item, sale_count, country) VALUES ('Shoes',    100, 'SF')
    INTO sales (item, sale_count, country) VALUES ('T shirts', 500, 'UK')
    INTO sales (item, sale_count, country) VALUES ('Pants',    100, 'Canada')
    INTO sales (item, sale_count, country) VALUES ('Pants',    100, 'Aus')
SELECT * FROM dual;

SELECT item, SUM(sale_count) AS "Total-Sales"
FROM sales
GROUP BY item;
/*
 item     | Total-Sales
 cap      | 550   (100 + 400 + 50)
 Shoes    | 300   (200 + 100)
 T shirts | 500
 Pants    | 200   (100 + 100)
*/

-- LISTAGG is Oracle's string aggregation
SELECT item, LISTAGG(country, ', ') WITHIN GROUP (ORDER BY country) AS countries
FROM sales
GROUP BY item;

-- ---------------------------------------------------------------
-- Example 2: votes per party, and HAVING to find the winner
-- ---------------------------------------------------------------
CREATE TABLE vote_count (
    voter_id       VARCHAR2(20)  NOT NULL,
    party          VARCHAR2(15)  NOT NULL,
    voter_name     VARCHAR2(20),
    is_valid_vote  NUMBER(1)     NOT NULL,
    PRIMARY KEY (voter_id)
);

INSERT ALL
    INTO vote_count (voter_id, party, voter_name, is_valid_vote) VALUES ('R4TYIOO78', 'PEP_DEMO', 'Roben James', 1)
    INTO vote_count (voter_id, party, voter_name, is_valid_vote) VALUES ('TTYIOO78',  'REP',      'Samantha F',  1)
    INTO vote_count (voter_id, party, voter_name, is_valid_vote) VALUES ('YTYIOO78',  'PEP_DEMO', 'Robert',      0)
    INTO vote_count (voter_id, party, voter_name, is_valid_vote) VALUES ('ATYIOO78',  'PEP_DEMO', 'Peter',       1)
    INTO vote_count (voter_id, party, voter_name, is_valid_vote) VALUES ('ETYROO78',  'PEP_DEMO', 'Stewiew',     1)
    INTO vote_count (voter_id, party, voter_name, is_valid_vote) VALUES ('TAQIOO78',  'PEP_DEMO', 'Lolitha',     1)
    INTO vote_count (voter_id, party, voter_name, is_valid_vote) VALUES ('ZTYIOO78',  'REP',      'Rama Rao',    1)
    INTO vote_count (voter_id, party, voter_name, is_valid_vote) VALUES ('UTYIOO78',  'REP',      'Chin Chan',   1)
SELECT * FROM dual;

-- All votes per party
SELECT party, COUNT(*) AS "Total-Votes"
FROM vote_count
GROUP BY party;
/*
 PEP_DEMO | 5
 REP      | 3
*/

-- Count only valid votes (WHERE filters rows before grouping),
-- then keep parties with more than 3 (HAVING filters groups)
SELECT party, COUNT(*) AS "Valid-Votes"
FROM vote_count
WHERE is_valid_vote = 1
GROUP BY party
HAVING COUNT(*) > 3;
/*
 PEP_DEMO | 4
*/

DROP TABLE sales;
DROP TABLE vote_count;
