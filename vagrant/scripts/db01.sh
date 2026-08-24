#!/bin/bash

set -e

echo "==> Installing MariaDB"
dnf install -y mariadb-server

echo "Enabling and starting MariaDB"
systemctl enable --now mariadb

echo "==> Securing the install (non-interactive equivalent of mysql_secure_installation)"
mysql -u root <<SQL
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
SQL


echo "Create databese, user, and privileges"
mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS accounts;
CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin123';
GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%';
FLUSH PRIVILEGES;
SQL

echo "==> Importing schema if not already exists"
if [ -f /home/rocky/db_backup.sql ]; then
	TABLE_COUNT=$(mysql -u root -N  -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='accounts';")
	if ["$TABLE_COUNT" -eq 0]; then
		mysql -u root accounts < /home/rocky/db_backup.sql
		echo "schema imported"
	else
		echo "Schema already present. Skipping import"
	fi
else
	echo "No db_backup.sql found yet at /home/rocky - skipping import for now. Upload it vi scp and import manualy "
fi

echo "==> Opening firewall for MySQL (if firewalld is active)"
if systemctl is-active --quiet firewalld; then
	firewall-cmd --permanent --add-port=3306/tcp
	firewall-cmd --reload
fi

echo "==> db01 provisionning complete "

