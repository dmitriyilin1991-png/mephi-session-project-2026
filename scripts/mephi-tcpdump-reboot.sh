set -euo pipefail
exec > >(tee "$HOME/mephi-session-project-2026/tcpdump-after-reboot.out") 2>&1
set -x
id user1
getcap /usr/sbin/tcpdump
test ! -u /usr/sbin/tcpdump
sudo -u user1 timeout 15s /usr/sbin/tcpdump -i lo -nn -c 2 icmp &
capture=$!
sleep 2
ping -c 2 127.0.0.1
wait "$capture"
printf 'PASS non-root capture after reboot; no SUID\n'
