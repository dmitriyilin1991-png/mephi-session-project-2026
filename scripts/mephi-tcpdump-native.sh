set -euo pipefail
export LANG=C LC_ALL=C
exec > >(tee "$HOME/mephi-session-project-2026/rpm-install-native.out") 2>&1
set -x
rpm -K /tmp/mephi-rpm/tcpdump-4.99.5-1.red80.x86_64.rpm
sudo rpm -Uvh --replacepkgs /tmp/mephi-rpm/tcpdump-4.99.5-1.red80.x86_64.rpm
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
