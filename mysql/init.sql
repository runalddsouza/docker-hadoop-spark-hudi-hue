CREATE DATABASE hue;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
GRANT ALL on hue.* to 'hue'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;