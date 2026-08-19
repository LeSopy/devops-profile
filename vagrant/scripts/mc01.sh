#!/bin/bash
 set -e

echo "==> Installing memcached"

dnf install -y memcached

echo "==> Configuring memcached to listen on all interfaces"
sed -i 's/^OPTIONS=.*/OPTIONS="-l 0.0.0.0"/' /etc/sysconfig/memcached

echo "==> Enabling and starting memcached"
systemctl enable --now memcached

echo "==> Opening firewalld for memcached (if firewalld is active)"
if systemctl is-active --quiet firewalld; then
	firewall-cmd --permanent --add-port=11211/tcp
	firewall-cmd --reload
fi

echo "==> mc01 provisioning complete"

