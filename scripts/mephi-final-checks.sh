set -euo pipefail
export LANG=C LC_ALL=C
uptime
bash "$HOME/verify_acl_after_reboot.sh"
sudo python3 "$HOME/verify_pam.py" | tee "$HOME/mephi-session-project-2026/auth-tests.out"
sudo python3 "$HOME/verify_auth.py" password | tee "$HOME/mephi-session-project-2026/password-tests.out"
bash "$HOME/collect_results.sh"
original_vt=$(sudo fgconsole)
trap 'sudo chvt "$original_vt"' EXIT
sudo openvt -c 8 -s -w -- bash /home/labadmin/show_console.sh
stat "$HOME/mephi-session-project-2026/mephi-screenshot.png"
