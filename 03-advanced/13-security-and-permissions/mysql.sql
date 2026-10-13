-- 13 · Users, roles and privileges in MySQL 8
-- Run as root (sudo mysql).

CREATE DATABASE IF NOT EXISTS shop;

-- A user is identified by name AND host
CREATE USER IF NOT EXISTS 'testuser1'@'localhost' IDENTIFIED BY 'testpassword';
CREATE USER IF NOT EXISTS 'report'@'%'            IDENTIFIED BY 'Rep0rt!pass';

-- Roles (MySQL 8.0+)
CREATE ROLE IF NOT EXISTS 'shop_read', 'shop_write';
GRANT SELECT ON shop.* TO 'shop_read';
GRANT SELECT, INSERT, UPDATE, DELETE ON shop.* TO 'shop_write';

GRANT 'shop_write' TO 'testuser1'@'localhost';
GRANT 'shop_read'  TO 'report'@'%';

-- Roles are not active on login unless set as default
SET DEFAULT ROLE ALL TO 'testuser1'@'localhost', 'report'@'%';

-- Direct grants also work, e.g. everything on one database
GRANT ALL PRIVILEGES ON shop.* TO 'testuser1'@'localhost';

-- FLUSH PRIVILEGES is only needed after editing the mysql.* grant tables by hand;
-- GRANT / REVOKE / CREATE USER take effect immediately.

SHOW GRANTS FOR 'testuser1'@'localhost';
SHOW GRANTS FOR 'report'@'%' USING 'shop_read';
SELECT User, Host FROM mysql.user;

-- Take privileges away
REVOKE ALL PRIVILEGES ON shop.* FROM 'testuser1'@'localhost';
REVOKE 'shop_write' FROM 'testuser1'@'localhost';

-- Clean up
DROP USER 'report'@'%';
DROP USER 'testuser1'@'localhost';
DROP ROLE 'shop_read', 'shop_write';
DROP DATABASE shop;
