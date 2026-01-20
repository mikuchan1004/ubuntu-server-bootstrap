#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-common.sh"

run_20_admin_user() {
  local user="$1" shell="$2" pubkey="$3" password="$4"
  log "[20] Admin user: $user"

  # create user if missing
  if ! id "$user" >/dev/null 2>&1; then
    useradd -m -s "$shell" "$user"
    log "Created user: $user"
  else
    log "User exists: $user"
    usermod -s "$shell" "$user" || true
  fi

  # ensure sudo group
  usermod -aG sudo "$user"

  # authorized_keys
  if [[ -n "$pubkey" ]]; then
    install -d -m 0700 -o "$user" -g "$user" "/home/$user/.ssh"
    printf '%s\n' "$pubkey" | install -m 0600 -o "$user" -g "$user" /dev/stdin "/home/$user/.ssh/authorized_keys"
    log "Installed admin authorized_keys"
  else
    warn "admin-pubkey empty (admin key not installed)"
  fi

  # optional password set
  if [[ -n "$password" ]]; then
    echo "${user}:${password}" | chpasswd
    log "Admin password set"
  fi

  log "[20] OK"
}
