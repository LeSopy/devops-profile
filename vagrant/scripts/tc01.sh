#!/bin/bash
set -e

echo "==> Installing JDK 17"
dnf install -y java-17-openjdk java-17-openjdk-devel

echo "==> Creating dedicated tomcat user (idempotent)"
if ! id -u tomcat &>/dev/null; then
    groupadd tomcat
    useradd -M -s /sbin/nologin -g tomcat -d /opt/tomcat tomcat
fi

echo "==> Installing Tomcat 9.0.120 (skip if already present)"
if [ ! -f /opt/tomcat/bin/catalina.sh ]; then
    cd /tmp
    curl -O https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.120/bin/apache-tomcat-9.0.120.tar.gz
    mkdir -p /opt/tomcat
    tar xzf apache-tomcat-9.0.120.tar.gz -C /opt/tomcat --strip-components=1
fi
chown -R tomcat:tomcat /opt/tomcat
chmod +x /opt/tomcat/bin/*.sh

echo "==> Writing systemd service"
JAVA_HOME_PATH=$(readlink -f $(which java) | sed 's:/bin/java::')
cat > /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=Apache Tomcat
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=${JAVA_HOME_PATH}"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

echo "==> Enabling and starting Tomcat"
systemctl daemon-reload
systemctl enable --now tomcat

echo "==> Opening firewall for 8080 (if firewalld is active)"
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-port=8080/tcp
    firewall-cmd --reload
fi

echo "==> Deploying the app WAR, if one has been built"
if [ -f /target/vprofile-v2.war ]; then
    rm -rf /opt/tomcat/webapps/ROOT
    cp /target/vprofile-v2.war /opt/tomcat/webapps/ROOT.war
    chown tomcat:tomcat /opt/tomcat/webapps/ROOT.war
    systemctl restart tomcat
    echo "WAR deployed."
else
    echo "No WAR found yet at target/vprofile-v2.war — skipping deploy. Run 'mvn clean package' on the host, then 'vagrant provision tc01' to deploy it."
fi

echo "==> tc01 provisioning complete"
