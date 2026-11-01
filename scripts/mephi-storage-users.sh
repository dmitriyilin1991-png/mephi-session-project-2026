#!/bin/bash
# Подготовка второго диска и пользователей учебного проекта; запуск: bash, нужны sudo, parted, ACL.
set -euo pipefail
export LANG=C LC_ALL=C
exec > >(tee "$HOME/mephi-session-project-2026/storage-users.out") 2>&1
set -x
test "$(lsblk -dnro SIZE /dev/sdb)" = "8G"
test "$(lsblk -nro TYPE /dev/sdb | wc -l)" -eq 1
test -z "$(sudo wipefs -n /dev/sdb)"
test "$(findmnt -no SOURCE /)" = "/dev/sda4"
sudo parted -s /dev/sdb mklabel gpt
sudo parted -s /dev/sdb mkpart primary ext4 1MiB 100%
sudo partprobe /dev/sdb
sudo udevadm settle
sudo mkfs.ext4 -L MEPHI_WEB /dev/sdb1
sudo mkdir -p /mephi-web
sudo cp -a /etc/fstab /root/mephi-backups/fstab.before
printf '%s\n' 'LABEL=MEPHI_WEB /mephi-web ext4 defaults 0 2' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo findmnt --verify --verbose
sudo mount /mephi-web
findmnt /mephi-web
lsblk -f
for account in user1 user2 user3 curator1 curator2 5501 5502 5503; do if getent passwd "$account"; then echo "CONFLICT $account"; exit 1; fi; done
for grp in developers curators 4444; do if getent group "$grp"; then echo "CONFLICT $grp"; exit 1; fi; done
sudo groupadd developers
sudo groupadd -g 4444 curators
sudo useradd -m -u 5501 -s /bin/bash -G developers user1
sudo useradd -m -u 5502 -s /bin/bash -G developers user2
sudo useradd -m -u 5503 -s /bin/bash -G developers user3
sudo useradd -m -s /bin/bash -G curators curator1
sudo useradd -m -s /bin/bash -G curators curator2
sudo install -d -m 0755 /data
sudo install -d -m 2770 -o root -g developers /data/mephi-2026
sudo setfacl -m u::rwx,g::rwx,g:curators:r-x,m::rwx,o::--- /data/mephi-2026
sudo setfacl -d -m u::rwx,g::rwx,g:curators:r-x,m::rwx,o::--- /data/mephi-2026
getfacl -p /data/mephi-2026
for account in user1 user2 user3 curator1 curator2; do id "$account"; done
