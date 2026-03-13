Create a New User

Example user: myuser
Password: mypassword

CREATE USER 'testuser1'@'localhost' IDENTIFIED BY 'testpassword';
6. Grant Permissions to the User
GRANT ALL PRIVILEGES ON mydatabase.* TO 'testuser1'@'localhost';

Reload privileges:

FLUSH PRIVILEGES;