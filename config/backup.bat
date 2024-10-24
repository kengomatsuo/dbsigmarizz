@echo off
set TIMESTAMP=%date:~-4,4%-%date:~-10,2%-%date:~-7,2%
set BACKUP_DIR=F:\backup
set MYSQL_USER=admin
set MYSQL_PASSWORD=admin
set DATABASE_NAME=library

mysqldump -u %MYSQL_USER% -p%MYSQL_PASSWORD% %DATABASE_NAME% > %BACKUP_DIR%\%DATABASE_NAME%-%TIMESTAMP%.sql
