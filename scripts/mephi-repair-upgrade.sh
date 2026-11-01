#!/bin/bash
# Исправление ошибочного preun одного пакета KDE; обновление штатными репозиториями, журнал repair-upgrade.out.
set -euo pipefail
export LANG=C LC_ALL=C
exec > >(tee "$HOME/mephi-session-project-2026/repair-upgrade.out") 2>&1
set -x
sudo alternatives --display redos-screenlocker-greet-kde
sudo alternatives --remove redos-screenlocker-greet-kde /usr/libexec/kscreenlocker_greet
sudo rpm -e --nopreun kscreenlocker
sudo dnf check
sudo dnf -y upgrade --refresh
sudo dnf -y install python3-pexpect
sudo dnf check
