#!/bin/bash
# Сбор реальных результатов проекта без хешей паролей.
# Запуск: bash collect_results.sh под labadmin после итоговой перезагрузки.
# Вход: настроенная учебная РЕД ОС; выход: ~/mephi-session-project-2026/.
set -euo pipefail
export LANG=C LC_ALL=C SYSTEMD_PAGER=cat
out="$HOME/mephi-session-project-2026"
mkdir -p "$out"
ping -c 4 8.8.8.8 > "$out/ping.out"
sudo dnf history > "$out/dnf.out"
stat /data/mephi-2026 > "$out/stat.out"
stat /mephi-web >> "$out/stat.out"
stat -c '%n %C' /data/mephi-2026 /mephi-web >> "$out/stat.out"
sudo getcap "$(readlink -f "$(command -v tcpdump)")" > "$out/getcap.out"
getenforce > "$out/getenforce.out"
sudo journalctl -u nginx -b --no-pager > "$out/journalctl.out"
curl -fsS http://localhost/ > "$out/curl.out"
test "$(cat "$out/curl.out")" = 'Hello from Student: 372396'
cp /etc/fstab "$out/fstab"
cp /etc/passwd "$out/passwd"
cp /etc/group "$out/group"
cp /etc/security/pwquality.conf "$out/pwquality.conf"
sudo awk -F: 'BEGIN {OFS=":"} {$2="[REDACTED]"; print}' /etc/shadow > "$out/shadow"
# Это настоящая история пользовательского Bash, а не синтетический список.
# Команды неинтерактивных SSH-этапов дополнительно сохранены в scripts/ и *.out.
bash -c 'set -o history; history -r "$HOME/.bash_history"; history' > "$out/history.out" 2> "$out/history-collection.out"
sudo getfacl -Rp /data/mephi-2026 > "$out/acl.out"
sudo cat /etc/nginx/nginx.conf > "$out/nginx.conf"
sudo cat /etc/systemd/system/nginx.service.d/mephi-mount.conf > "$out/nginx-mount.conf"
sudo cat /etc/pam.d/login > "$out/pam-login.conf"
sudo cat /etc/security/mephi-console-access.conf > "$out/mephi-console-access.conf"
sudo semanage fcontext -l -C > "$out/selinux-local-contexts.out"
{
    date --iso-8601=seconds
    cat /etc/os-release
    uname -r
    hostnamectl --static
    nmcli -f connection.id,connection.autoconnect,ipv4.method connection show enp0s3
    systemctl get-default
    findmnt /mephi-web
    lsblk -f
    systemctl is-enabled nginx sshd
    systemctl is-active nginx sshd
    systemctl show nginx -p RequiresMountsFor
    getenforce
    ls -Zd /mephi-web /mephi-web/index.html
    sudo nginx -t
    curl -fsS http://localhost/
    sudo getcap "$(readlink -f "$(command -v tcpdump)")"
    stat -c '%a %U %n' "$(readlink -f "$(command -v tcpdump)")"
    for user in user1 user2 user3 curator1 curator2 labadmin; do
        id "$user"
        sudo chage -l "$user"
    done
    sudo authselect check
    sudo findmnt --verify --verbose
    sudo dnf check
} > "$out/post-reboot.out" 2>&1
printf '%s\n' 'Collection complete; screenshot and functional test logs must be checked separately.'
