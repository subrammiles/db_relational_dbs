-- 12 · PIVOT, UNPIVOT and ROLLUP in Oracle

CREATE TABLE sales (
    region   VARCHAR2(10),
    quarter  VARCHAR2(2),
    amount   NUMBER
);

INSERT ALL
    INTO sales VALUES ('North', 'Q1', 100)
    INTO sales VALUES ('North', 'Q2', 150)
    INTO sales VALUES ('North', 'Q3', 120)
    INTO sales VALUES ('South', 'Q1',  90)
    INTO sales VALUES ('South', 'Q2',  60)
    INTO sales VALUES ('South', 'Q4', 200)
SELECT * FROM dual;

-- PIVOT: one column per quarter
SELECT *
FROM (SELECT region, quarter, amount FROM sales)
PIVOT (SUM(amount) FOR quarter IN ('Q1' AS q1, 'Q2' AS q2, 'Q3' AS q3, 'Q4' AS q4))
ORDER BY region;
/*
REGION  Q1   Q2   Q3   Q4
North   100  150  120
South    90   60       200
*/

-- UNPIVOT: back to rows
WITH wide AS (
    SELECT *
    FROM (SELECT region, quarter, amount FROM sales)
    PIVOT (SUM(amount) FOR quarter IN ('Q1' AS q1, 'Q2' AS q2, 'Q3' AS q3, 'Q4' AS q4))
)
SELECT region, quarter, amount
FROM wide
UNPIVOT (amount FOR quarter IN (q1 AS 'Q1', q2 AS 'Q2', q3 AS 'Q3', q4 AS 'Q4'))
ORDER BY region, quarter;

-- ROLLUP with labels
SELECT DECODE(GROUPING(region), 1, 'ALL', region)       AS region,
       DECODE(GROUPING(quarter), 1, 'TOTAL', quarter)   AS quarter,
       SUM(amount)                                      AS amount
FROM sales
GROUP BY ROLLUP (region, quarter)
ORDER BY GROUPING(region), region, GROUPING(quarter), quarter;

-- CUBE
SELECT region, quarter, SUM(amount)
FROM sales
GROUP BY CUBE (region, quarter);

DROP TABLE sales;
