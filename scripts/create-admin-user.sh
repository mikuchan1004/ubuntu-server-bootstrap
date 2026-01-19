sudo tee /usr/local/sbin/create-admin-user.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

# =====================================================
# create-admin-user.sh
# - Create a standard admin user
# - Add to sudo
# - (Optional) Inject SSH public key into authorized_keys
#
# Ubuntu-friendly:
# - If group with same name exists, reuse it (-g <group>)
# - If not, create user with its own primary group (-U)
#
# Usage:
#   sudo create-admin-user.sh <username> ["ssh-ed25519 AAAA... comment"]
#   sudo create-admin-user.sh admin
#   sudo create-admin-user.sh admin "ssh-ed25519 AAAA... your@pc"
# =====================================================

if [[ $EUID -ne 0 ]]; then
  echo "[-] Run as root (sudo)."
  exit 1
fi

USER_NAME="${1:-admin}"
PUBKEY="${2:-}"

log() { echo "[*] $*"; }
ok()  { echo "[+] $*"; }
warn(){ echo "[!] $*" >&2; }

# Validate username (simple, safe)
if [[ ! "$USER_NAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  echo "[-] Invalid username: $USER_NAME"
  echo "    Use: lowercase letters, digits, _, -, and must start with a letter/_"
  exit 2
fi

create_user_if_missing() {
  if id "$USER_NAME" >/dev/null 2>&1; then
    log "User exists: $USER_NAME"
    return 0
  fi

  if getent group "$USER_NAME" >/dev/null 2>&1; then
    log "Group '$USER_NAME' exists → creating user with primary group '$USER_NAME'"
    useradd -m -s /bin/bash -g "$USER_NAME" "$USER_NAME"
  else
    log "Group '$USER_NAME' does not exist → creating user with its own primary group"
    # -U creates a group with the same name as the user
    useradd -m -s /bin/bash -U "$USER_NAME"
    usermod -s /bin/bash "$USER_NAME"
  fi

  ok "User created: $USER_NAME"
}

ensure_sudo() {
  usermod -aG sudo "$USER_NAME"
  ok "Added to sudo group: $USER_NAME"
}

ensure_ssh_key() {
  if [[ -z "$PUBKEY" ]]; then
    warn "No public key provided. (This is OK.)"
    echo "    To add later:"
    echo "      sudo -u $USER_NAME mkdir -p /home/$USER_NAME/.ssh"
    echo "      sudo -u $USER_NAME nano /home/$USER_NAME/.ssh/authorized_keys"
    return 0
  fi

  # Basic sanity check (don’t over-reject)
  if [[ ! "$PUBKEY" =~ ^ssh-(ed25519|rsa|ecdsa) ]]; then
    warn "The provided key doesn't look like a typical SSH public key."
    warn "I'll still write it as-is. (If you pasted wrong text, fix it later.)"
  fi

  HOME_DIR="$(eval echo "~$USER_NAME")"
  SSH_DIR="$HOME_DIR/.ssh"
  AUTH_KEYS="$SSH_DIR/authorized_keys"

  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  touch "$AUTH_KEYS"
  chmod 600 "$AUTH_KEYS"
  chown -R "$USER_NAME:$USER_NAME" "$SSH_DIR"

  if grep -qF "$PUBKEY" "$AUTH_KEYS"; then
    log "Public key already present in $AUTH_KEYS"
  else
    echo "$PUBKEY" >> "$AUTH_KEYS"
    ok "Public key added to $AUTH_KEYS"
  fi
}

print_next_steps() {
  echo
  ok "Done."
  echo "Next:"
  echo "  1) Set password (optional):"
  echo "     passwd $USER_NAME"
  echo "  2) Test sudo:"
  echo "     su - $USER_NAME"
  echo "     sudo whoami"
  echo
  echo "User info:"
  id "$USER_NAME" || true
}

create_user_if_missing
ensure_sudo
ensure_ssh_key
print_next_steps
EOF

sudo chmod +x /usr/local/sbin/create-admin-user.sh
sudo ls -l /usr/local/sbin/create-admin-user.sh
