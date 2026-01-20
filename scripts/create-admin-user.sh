#!/usr/bin/env bash
set -Eeuo pipefail

msg()  { echo "[*] $*"; }
ok()   { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[-] $*"; exit 1; }

trap 'warn "create-admin-user.sh failed"; exit 1' ERR
[[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root (use sudo)."

USER_NAME="${1:-}"
PUBKEY="${2:-}"
[[ -n "$USER_NAME" ]] || die "Usage: $0 <username> [public_key]"

if [[ ! "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  die "Invalid username: $USER_NAME"
fi

msg "Ensuring group '$USER_NAME' exists..."
getent group "$USER_NAME" >/dev/null || groupadd "$USER_NAME"

if id "$USER_NAME" >/dev/null 2>&1; then
  ok "User '$USER_NAME' already exists"
else
  msg "Creating user '$USER_NAME'..."
  useradd -m -s /bin/bash -g "$USER_NAME" "$USER_NAME"
  ok "User created"
fi

msg "Ensuring sudo access..."
usermod -aG sudo "$USER_NAME"

if [[ -n "${ADMIN_PASSWORD:-}" ]]; then
  msg "Setting password for '$USER_NAME' (non-interactive)"
  echo "$USER_NAME:$ADMIN_PASSWORD" | chpasswd
  ok "Password set"
else
  warn "ADMIN_PASSWORD not set. (If you want a password: sudo passwd $USER_NAME)"
fi

if [[ -n "$PUBKEY" ]]; then
  msg "Installing public key for '$USER_NAME'..."
  HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
  SSH_DIR="$HOME_DIR/.ssh"
  AUTH_KEYS="$SSH_DIR/authorized_keys"

  install -d -m 0700 -o "$USER_NAME" -g "$USER_NAME" "$SSH_DIR"
  touch "$AUTH_KEYS"
  chown "$USER_NAME:$USER_NAME" "$AUTH_KEYS"
  chmod 0600 "$AUTH_KEYS"

  grep -qxF "$PUBKEY" "$AUTH_KEYS" || echo "$PUBKEY" >> "$AUTH_KEYS"
  ok "Public key installed"
else
  warn "No public key provided. (Recommended: pass a .pub line as 2nd argument)"
fi

ok "Done. User: $USER_NAME (sudo enabled)"
