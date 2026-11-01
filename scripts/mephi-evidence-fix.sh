set -euo pipefail
export LANG=C LC_ALL=C
bash -c 'set -o history; history -r "$HOME/.bash_history"; history' > "$HOME/mephi-session-project-2026/history.out"
wc -l "$HOME/.bash_history" "$HOME/mephi-session-project-2026/history.out"
{
 for u in user1 user2 user3 curator1 curator2 labadmin root; do
  printf 'Account: %s\n' "$u"
  sudo /usr/bin/chage -l "$u"
 done
 sudo awk -F: '$1 ~ /^(user[123]|curator[12]|labadmin|root)$/ {printf "%s: last_change=%s min_days=%s max_days=%s warn_days=%s\n",$1,$3,$4,$5,$6; if ($5 != 90) exit 1}' /etc/shadow
 echo 'Configured PAM pwquality:'
 grep pam_pwquality /etc/pam.d/system-auth
 echo 'GUI package check:'
 if rpm -q sddm plasma-workspace xorg-x11-server-Xorg xorg-x11-server-Xwayland; then exit 1; fi
} > "$HOME/mephi-session-project-2026/policy-details.out" 2>&1
cat "$HOME/mephi-session-project-2026/policy-details.out"
