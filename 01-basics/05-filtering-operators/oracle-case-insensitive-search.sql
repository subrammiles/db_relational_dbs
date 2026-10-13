-- 05 · Case- and accent-insensitive search in Oracle
--
-- By default Oracle compares strings byte by byte (NLS_COMP = BINARY), so
-- 'jose', 'Jose', 'JOSE', 'José' are all different. Switching the session to
-- linguistic comparison with the BINARY_AI sort ("accent insensitive", which
-- also implies case insensitive) makes them all equal.

CREATE TABLE t1 (
    id   NUMBER,
    col  VARCHAR2(15),
    CONSTRAINT t1_pk PRIMARY KEY (id)
);

INSERT INTO t1 VALUES (1, 'jose');
INSERT INTO t1 VALUES (2, 'Jose');
INSERT INTO t1 VALUES (3, 'JOSE');
INSERT INTO t1 VALUES (4, 'José');
INSERT INTO t1 VALUES (5, 'JOSÉ');
COMMIT;

-- Binary comparison: only row 1
SELECT col FROM t1 WHERE col LIKE '%jose%';

-- Without an index on the linguistic value every search is a full scan,
-- so create a function-based index that matches the session setting
CREATE INDEX idx_t1_col_ai ON t1 (NLSSORT(col, 'NLS_SORT = BINARY_AI'));

ALTER SESSION SET NLS_COMP = 'LINGUISTIC';
ALTER SESSION SET NLS_SORT = 'BINARY_AI';

-- Now all 5 rows match
SELECT col FROM t1 WHERE col LIKE '%jose%';
SELECT col FROM t1 WHERE col = 'jose';

-- Put the session back when you're done
ALTER SESSION SET NLS_COMP = 'BINARY';
ALTER SESSION SET NLS_SORT = 'BINARY';

-- The same switch from inside PL/SQL needs dynamic SQL,
-- because ALTER SESSION is not allowed directly in a PL/SQL block:
BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_COMP = LINGUISTIC';
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_SORT = BINARY_AI';
END;
/

ALTER SESSION SET NLS_COMP = 'BINARY';
ALTER SESSION SET NLS_SORT = 'BINARY';

-- Oracle 12.2+: declare the column itself case-insensitive instead
-- CREATE TABLE t2 (col VARCHAR2(15) COLLATE BINARY_CI);

DROP TABLE t1;
