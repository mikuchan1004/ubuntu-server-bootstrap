#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# Ubuntu Server Bootstrap - install.sh
# - Idempotent: safe to run multiple times
# - Safe SSH changes: validate before apply
# - Logs: /var/log/ubuntu-server-bootstrap.log
# ==========================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/00-common.sh"

ADMIN_USER="admin"
ADMIN_SHELL="/bin/bash"
ADMIN_PUBKEY=""              # Public key line (ssh-ed25519... or ssh-rsa...)
ALLOW_PASSWORD_SSH="true"    # true/false
SET_ADMIN_PASSWORD=""        # optional: sets admin password (not recommended to pass via CLI)
TIMEZONE="Asia/Seoul"

SWAP_MB="2048"
JOURNAL_MAX_USE="200M"
JOURNAL_MAX_FILE="50M"

usage() {
  cat <<'EOF'
Usage:
  sudo bash install.sh [options]

Options:
  --admin-user <name>                (default: admin)
  --admin-pubkey "<ssh public key>"  (optional) Installs into ~/.ssh/authorized_keys
  --allow-password-ssh <true|false>  (default: true)
  --set-admin-password "<pw>"        (optional) Sets admin password (security risk if typed in shell history)
  --timezone <TZ>                    (default: Asia/Seoul)
  --swap-mb <MB>                     (default: 2048)
  --journal-max-use <size>           (default: 200M)
  --journal-max-file <size>          (default: 50M)

Examples:
  sudo bash install.sh --admin-user admin --admin-pubkey "$(cat ./keys/admin.pub)" --allow-password-ssh true

Notes:
  - SSH "Connection timed out" is almost always OCI NSG/Security List issue (cloud-side), not server-side.
  - This script standardizes server configuration safely and repeatably.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --admin-user) ADMIN_USER="$2"; shift 2;;
    --admin-pubkey) ADMIN_PUBKEY="$2"; shift 2;;
    --allow-password-ssh) ALLOW_PASSWORD_SSH="$2"; shift 2;;
    --set-admin-password) SET_ADMIN_PASSWORD="$2"; shift 2;;
    --timezone) TIMEZONE="$2"; shift 2;;
    --swap-mb) SWAP_MB="$2"; shift 2;;
    --journal-max-use) JOURNAL_MAX_USE="$2"; shift 2;;
    --journal-max-file) JOURNAL_MAX_FILE="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "Unknown option: $1";;
  esac
done

require_root
ensure_ubuntu

log "=== Ubuntu Server Bootstrap starting ==="
log "ADMIN_USER=$ADMIN_USER"
log "ALLOW_PASSWORD_SSH=$ALLOW_PASSWORD_SSH"
log "TIMEZONE=$TIMEZONE"

source "$SCRIPT_DIR/scripts/10-init.sh"
source "$SCRIPT_DIR/scripts/20-admin-user.sh"
source "$SCRIPT_DIR/scripts/30-ssh.sh"
source "$SCRIPT_DIR/scripts/40-motd-banner.sh"

run_10_init "$TIMEZONE" "$SWAP_MB" "$JOURNAL_MAX_USE" "$JOURNAL_MAX_FILE"
run_20_admin_user "$ADMIN_USER" "$ADMIN_SHELL" "$ADMIN_PUBKEY" "$SET_ADMIN_PASSWORD"
run_30_ssh "$ALLOW_PASSWORD_SSH"
run_40_motd_banner

log "=== Done ==="
log "Log file: $LOG_FILE"
log "Tip: Validate cloud-side port 22 first -> from your PC:"
log "  PowerShell: Test-NetConnection <PUBLIC_IP> -Port 22"
