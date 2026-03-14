# pull the image:
docker pull container-registry.oracle.com/database/express:21.3.0-xe

#
Run the Oracle XE container
docker run -d \
  --name oracle-xe \
  -p 1521:1521 \
  -p 5500:5500 \
  -e ORACLE_PWD=Oracle123 \
  container-registry.oracle.com/database/express:21.3.0-xe

Explanation:

1521 → Oracle DB port
5500 → Oracle EM Express UI
ORACLE_PWD → password for SYS, SYSTEM, PDBADMIN
oracle-xe → container name


3.Check if container is running:

docker ps

4.
Enter the container

Run:

docker exec -it oracle-xe bash

Now you are inside the Oracle container.

5.
Connect to SQL*Plus

Run:

sqlplus sys/Oracle123@//localhost:1521/XEPDB1 as sysdba

or

sqlplus sys as sysdba

Enter password: Oracle123

You should see:

SQL>


4. Check the pluggable database

Oracle XE uses a PDB called XEPDB1.

Switch to it:

ALTER SESSION SET CONTAINER=XEPDB1;

Check:

show con_name;

Output should be:

XEPDB1
5. Create a new user

Example user: appuser

CREATE USER appuser IDENTIFIED BY apppass;

Grant permissions:

GRANT CONNECT, RESOURCE TO appuser;

Allow unlimited tablespace:

ALTER USER appuser QUOTA UNLIMITED ON USERS;
6. Connect as the new user

Exit sqlplus:

exit

Reconnect:

sqlplus appuser/apppass@//localhost:1521/XEPDB1
7. Create a table

Example table:

CREATE TABLE employees (
  id NUMBER PRIMARY KEY,
  name VARCHAR2(50),
  salary NUMBER
);

Insert data:

INSERT INTO employees VALUES (1, 'John', 5000);
INSERT INTO employees VALUES (2, 'Alice', 6000);

Commit:

COMMIT;