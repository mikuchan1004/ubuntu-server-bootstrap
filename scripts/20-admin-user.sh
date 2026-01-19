#!/usr/bin/env bash
set -Eeuo pipefail
run_20_admin_user(){
  local u="$1"; local k="$3"
  id "$u" || useradd -m -s /bin/bash "$u"
  usermod -aG sudo "$u"
  if [[ -n "$k" ]]; then
    h=$(eval echo "~$u")
    install -d -m700 -o "$u" -g "$u" "$h/.ssh"
    echo "$k" > "$h/.ssh/authorized_keys"
    chown "$u:$u" "$h/.ssh/authorized_keys"
    chmod 600 "$h/.ssh/authorized_keys"
  fi
}
