#!/bin/bash
# Подготовка учебной VM: диагностика, сеть, штатная остановка фоновых обновлений.
set -euo pipefail
export LANG=C LC_ALL=C SYSTEMD_PAGER=cat
mkdir -p "$HOME/mephi-session-project-2026"
exec > >(tee "$HOME/mephi-session-project-2026/preflight.out") 2>&1
sudo install -d -m 700 /root/mephi-backups
cat /etc/os-release
uname -r
id
sudo -n true
sudo systemctl enable sshd
sudo hostnamectl set-hostname mephi-2026.domain.local
sudo timedatectl set-timezone Asia/Irkutsk
nmcli -f connection.id,connection.autoconnect,ipv4.method connection show enp0s3
ip -br address
ip route
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,UUID,MOUNTPOINTS
sudo wipefs -n /dev/sdb
sudo blkid /dev/sdb || test $? -eq 2
getenforce
sestatus
sudo systemctl stop dnf-makecache.timer dnf-makecache.service
sudo systemctl stop dnfdaemon.service
sudo systemctl mask --runtime dnfdaemon.service
ps -eo pid,ppid,etime,stat,comm,args | grep -E 'dnf|rpm|packagekit' | grep -v grep || true
sudo dnf history
ping -c 4 8.8.8.8 | tee "$HOME/mephi-session-project-2026/ping.out"
sudo dnf repolist
sudo dnf -y install nginx libcap-ng-utils acl libcap policycoreutils-python-utils e2fsprogs parted curl dnf-plugins-core libpwquality