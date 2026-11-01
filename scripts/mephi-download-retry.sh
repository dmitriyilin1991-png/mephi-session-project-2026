set -euo pipefail
if ps -p 1318 -o args= | grep -q 'dnf download --destdir=/tmp/mephi-rpm tcpdump'; then kill -INT 1318; fi
for i in {1..15}; do kill -0 1318 2>/dev/null || break; sleep 1; done
if kill -0 1318 2>/dev/null; then echo 'Download still stopping'; exit 1; fi
exec > >(tee "$HOME/mephi-session-project-2026/rpm-install-retry.out") 2>&1
set -x
sudo dnf --disablerepo='*' --enablerepo=base --enablerepo=updates download --destdir=/tmp/mephi-rpm tcpdump
rpm -K /tmp/mephi-rpm/tcpdump*.rpm
sudo rpm -Uvh --replacepkgs /tmp/mephi-rpm/tcpdump*.rpm
path=$(readlink -f "$(command -v tcpdump)")
sudo chmod u-s "$path"
sudo setcap cap_net_raw,cap_net_admin=ep "$path"
getcap "$path"
sudo -u user1 timeout 15s tcpdump -i lo -nn -c 2 icmp > "$HOME/mephi-session-project-2026/tcpdump-test.out" 2>&1 &
capture=$!
sleep 2
ping -c 2 127.0.0.1
wait "$capture"
cat "$HOME/mephi-session-project-2026/tcpdump-test.out"
sudo dnf --disablerepo='*' --enablerepo=base --enablerepo=updates -q list --available fbgrab
