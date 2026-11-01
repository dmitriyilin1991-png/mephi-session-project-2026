#!/bin/bash
# Проверка наследования ACL и запретов от имени учебных пользователей; вход: готовый каталог проекта; выход: access-tests.out и acl.out.
set -euo pipefail
export LANG=C LC_ALL=C
exec > >(tee "$HOME/mephi-session-project-2026/access-tests.out") 2>&1
base=/data/mephi-2026
for owner in user1 user2 user3; do
  sudo -u "$owner" bash -c 'umask 077; mkdir -p "$1/$2-dir"; printf "created by %s\n" "$2" > "$1/$2.txt"; printf "nested\n" > "$1/$2-dir/nested.txt"' _ "$base" "$owner"
done
for actor in user1 user2 user3; do
  for owner in user1 user2 user3; do
    sudo -u "$actor" bash -c 'cat "$1/$2.txt" >/dev/null; printf "edited by %s\n" "$3" >> "$1/$2.txt"; printf "edited\n" >> "$1/$2-dir/nested.txt"' _ "$base" "$owner" "$actor"
    printf 'PASS developer %s reads/writes %s files\n' "$actor" "$owner"
  done
done
deny() {
  local actor="$1"; shift
  if sudo -u "$actor" "$@" 2>/dev/null; then printf 'FAIL unexpected permission for %s: %s\n' "$actor" "$*"; exit 1; else printf 'PASS denied %s: %s\n' "$actor" "$*"; fi
}
for curator in curator1 curator2; do
  for owner in user1 user2 user3; do
    sudo -u "$curator" cat "$base/$owner.txt" "$base/$owner-dir/nested.txt" >/dev/null
    printf 'PASS curator %s reads %s files\n' "$curator" "$owner"
    deny "$curator" bash -c 'printf forbidden >> "$1"' _ "$base/$owner.txt"
    deny "$curator" touch "$base/$owner-dir/forbidden"
    deny "$curator" rm "$base/$owner.txt"
    deny "$curator" mv "$base/$owner.txt" "$base/$owner-renamed"
  done
done
deny labadmin ls "$base"
deny labadmin cat "$base/user1.txt"
deny labadmin bash -c 'cd "$1"' _ "$base"
deny labadmin touch "$base/forbidden"
sudo getfacl -Rp "$base" > "$HOME/mephi-session-project-2026/acl.out"
echo 'ALL DAC CHECKS PASSED'
