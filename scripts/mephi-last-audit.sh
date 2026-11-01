set -euo pipefail
export LANG=C LC_ALL=C
{
 echo 'Current-boot PAM evidence:'
 sudo journalctl -b --no-pager | grep 'pam_access(login:account)' || true
 echo 'SELinux context verification (no changes):'
 sudo restorecon -nRv /mephi-web
 matchpathcon -V /mephi-web /mephi-web/index.html
 echo 'Package consistency:'
 sudo dnf check
 echo 'Package verification for chage:'
 rpm -qf /usr/bin/chage
 rpm -V shadow-utils || true
 echo 'Root remains locked:'
 sudo passwd -S root
 echo 'Failed system services:'
 systemctl --failed --no-pager
} | tee "$HOME/mephi-session-project-2026/final-audit.out"
