#!/bin/bash
# Реальные команды на выделенной tty8 для снимка экрана; вывод: PNG в каталоге результатов.
# Запускать root через openvt -c 8 -s -w -- bash /home/labadmin/show_console.sh.
set -euo pipefail
export LANG=C LC_ALL=C TERM=linux
clear
PS4='$ '
set -x
hostname
date --iso-8601=seconds
getenforce
findmnt /mephi-web
systemctl is-active nginx
curl http://localhost/
getcap /usr/sbin/tcpdump
set +x
sleep 2
python3 /home/labadmin/capture_console.py /home/labadmin/mephi-session-project-2026/mephi-screenshot.png
chown labadmin:labadmin /home/labadmin/mephi-session-project-2026/mephi-screenshot.png
