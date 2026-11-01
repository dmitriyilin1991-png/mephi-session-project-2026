#!/bin/bash
# Настройка nginx на отдельном ext4 и постоянных контекстов SELinux; запуск bash с sudo.
set -euo pipefail
export LANG=C LC_ALL=C
exec > >(tee "$HOME/mephi-session-project-2026/nginx-setup.out") 2>&1
set -x
test "$(findmnt -nro SOURCE /mephi-web)" = "/dev/sdb1"
test "$(getenforce)" = Enforcing
sudo cp -a /etc/nginx/nginx.conf /root/mephi-backups/nginx.conf.before
printf '%s\n' 'Hello from Student: 372396' | sudo tee /mephi-web/index.html
sudo chown root:root /mephi-web /mephi-web/index.html
sudo chmod 0755 /mephi-web
sudo chmod 0644 /mephi-web/index.html
sudo semanage fcontext -a -t httpd_sys_content_t '/mephi-web(/.*)?'
sudo restorecon -RFv /mephi-web
sudo sed -i 's@root         /usr/share/nginx/html;@root         /mephi-web;@' /etc/nginx/nginx.conf
sudo mkdir -p /etc/systemd/system/nginx.service.d
printf '%s\n' '[Unit]' 'RequiresMountsFor=/mephi-web' | sudo tee /etc/systemd/system/nginx.service.d/mephi-mount.conf
sudo systemctl daemon-reload
sudo nginx -t
sudo systemctl enable --now nginx
systemctl is-enabled nginx
systemctl is-active nginx
ls -Zd /mephi-web /mephi-web/index.html
curl -fsS http://localhost/ | tee "$HOME/mephi-session-project-2026/curl.out"
test "$(curl -fsS http://localhost/)" = 'Hello from Student: 372396'
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --get-zone-of-interface=enp0s3
