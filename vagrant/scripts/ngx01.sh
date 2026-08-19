#!/bin/bash
set -e

echo "==> Installing nginx"
apt update
apt install -y nginx

echo "==> Writing reverse-proxy config"
cat > /etc/nginx/sites-available/vprofile << 'EOF'
server {
    listen 80;
    server_name ngx01;

    location / {
        proxy_pass http://tc01:8080/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

echo "==> Enabling the site, disabling the default"
ln -sf /etc/nginx/sites-available/vprofile /etc/nginx/sites-enabled/vprofile
rm -f /etc/nginx/sites-enabled/default

echo "==> Testing and reloading nginx"
nginx -t
systemctl restart nginx

echo "==> Opening firewall for HTTP (if ufw is active)"
if systemctl is-active --quiet ufw; then
    ufw allow 80/tcp
fi

echo "==> ngx01 provisioning complete"
