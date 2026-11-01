#!/bin/bash
# Перевод учебной VM в консольный режим и обновление; запуск bash, требуется sudo/dnf.
set -euo pipefail
export LANG=C LC_ALL=C SYSTEMD_PAGER=cat
exec > >(tee "$HOME/mephi-session-project-2026/console-upgrade.out") 2>&1
set -x
sudo systemctl set-default multi-user.target
sudo systemctl disable --now sddm
sudo dnf -y --setopt=clean_requirements_on_remove=False remove 'plasma-*' 'kwin*' 'sddm*' xorg-x11-server-Xorg xorg-x11-server-Xwayland dnfdragora dnfdragora-updater
sudo dnf -y upgrade --refresh
sudo dnf check
systemctl get-default
