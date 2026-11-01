#!/bin/bash
# Настройка парольной политики и запрета консольного входа кураторов; парольные значения не обрабатываются.
set -euo pipefail
export LANG=C LC_ALL=C
exec > >(tee "$HOME/mephi-session-project-2026/auth-config.out") 2>&1
set -x
sudo cp -a /etc/pam.d/login /root/mephi-backups/pam-login.before
sudo cp -a /etc/login.defs /root/mephi-backups/login.defs.before
sudo cp -a /etc/security/pwquality.conf /root/mephi-backups/pwquality.conf.before
sudo authselect check
sudo find /etc/security/pwquality.conf.d -type f -maxdepth 1 -print 2>/dev/null || true
sudo sed -i '/^account.*pam_nologin.so/a account required pam_access.so accessfile=/etc/security/mephi-console-access.conf' /etc/pam.d/login
printf '%s\n' '- : (curators) : ALL' '+ : ALL : ALL' | sudo tee /etc/security/mephi-console-access.conf
sudo chmod 0644 /etc/security/mephi-console-access.conf
sudo restorecon /etc/pam.d/login /etc/security/mephi-console-access.conf
sudo sed -i -E 's/^PASS_MAX_DAYS[[:space:]]+.*/PASS_MAX_DAYS   90/' /etc/login.defs
printf '\n# MEPHI session project: at least 12 actual characters\nminlen = 12\ndcredit = 0\nucredit = 0\nlcredit = 0\nocredit = 0\nenforcing = 1\nenforce_for_root\n' | sudo tee -a /etc/security/pwquality.conf
for account in user1 user2 user3 curator1 curator2 labadmin root; do sudo chage -M 90 "$account"; sudo chage -l "$account"; done
sudo authselect check
sudo cat /etc/pam.d/login
sudo grep -E '^[^#[:space:]]' /etc/security/pwquality.conf
