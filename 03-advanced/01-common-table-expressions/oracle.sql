-- 01 · Hierarchical queries in Oracle: CONNECT BY and recursive WITH

CREATE TABLE emp (
    emp_id      NUMBER PRIMARY KEY,
    name        VARCHAR2(30),
    manager_id  NUMBER REFERENCES emp (emp_id)
);

INSERT ALL
    INTO emp VALUES (1, 'Asha',   NULL)
    INTO emp VALUES (2, 'Vikram', 1)
    INTO emp VALUES (3, 'Priya',  2)
    INTO emp VALUES (4, 'Rahul',  2)
    INTO emp VALUES (5, 'Arjun',  3)
    INTO emp VALUES (6, 'Meera',  1)
SELECT * FROM dual;

-- Oracle's classic hierarchical syntax
--   START WITH  : the root rows (anchor)
--   CONNECT BY  : how a child relates to its parent; PRIOR marks the parent side
--   LEVEL       : depth, 1 for roots
SELECT LPAD(' ', (LEVEL - 1) * 4) || name AS org_chart,
       LEVEL,
       SYS_CONNECT_BY_PATH(name, ' > ') AS path,
       CONNECT_BY_ISLEAF AS is_leaf
FROM emp
START WITH manager_id IS NULL
CONNECT BY PRIOR emp_id = manager_id
ORDER SIBLINGS BY name;

-- Walk up from Arjun to the root
SELECT name, LEVEL
FROM emp
START WITH emp_id = 5
CONNECT BY emp_id = PRIOR manager_id;

-- Generate the numbers 1..10 with CONNECT BY on DUAL (a common Oracle idiom)
SELECT LEVEL AS n FROM dual CONNECT BY LEVEL <= 10;

-- The standard recursive WITH works in Oracle 11gR2+ (no RECURSIVE keyword,
-- and the CTE must list its column names)
WITH org (emp_id, name, manager_id, lvl) AS (
    SELECT emp_id, name, manager_id, 1 FROM emp WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.name, e.manager_id, o.lvl + 1
    FROM emp e JOIN org o ON e.manager_id = o.emp_id
)
SELECT * FROM org ORDER BY lvl, name;

DROP TABLE emp;
