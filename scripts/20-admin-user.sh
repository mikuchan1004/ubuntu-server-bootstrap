#!/usr/bin/env bash
set -Eeuo pipefail

run_20_admin_user() {
  local user="$1"
  local shell="$2"
  local pubkey="$3"
  local set_pw="$4"

  log "[20-admin-user] Ensure admin user: $user"

  # Create user if missing
  if id "$user" >/dev/null 2>&1; then
    log "[20-admin-user] User exists: $user"
  else
    log "[20-admin-user] Creating user: $user"
    useradd -m -s "$shell" "$user"
  fi

  # Ensure sudo group membership (idempotent)
  usermod -aG sudo "$user"

  # Optional: set password (discouraged to pass in CLI)
  if [[ -n "$set_pw" ]]; then
    log "[20-admin-user] Setting password for $user"
    echo "${user}:${set_pw}" | chpasswd
  fi

  # Setup SSH authorized_keys if provided
  if [[ -n "$pubkey" ]]; then
    log "[20-admin-user] Installing authorized_keys for $user"
    local home_dir
    home_dir="$(eval echo "~$user")"
    install -d -m 0700 -o "$user" -g "$user" "$home_dir/.ssh"

    # sanitize: single line key
    pubkey="$(echo "$pubkey" | tr -d '\r\n')"

    local ak="$home_dir/.ssh/authorized_keys"
    touch "$ak"
    chown "$user:$user" "$ak"
    chmod 0600 "$ak"

    grep -qxF "$pubkey" "$ak" || echo "$pubkey" >> "$ak"
  else
    log "[20-admin-user] No pubkey provided -> skip authorized_keys"
  fi

  log "[20-admin-user] Done"
}
