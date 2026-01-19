#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/00-common.sh"

ADMIN_USER="admin"
ADMIN_SHELL="/bin/bash"
ADMIN_PUBKEY=""
ALLOW_PASSWORD_SSH="true"
SET_ADMIN_PASSWORD=""
TIMEZONE="Asia/Seoul"
PROFILE="dev"
DISABLE_CLOUD_INIT="false"

SWAP_MB="2048"
JOURNAL_MAX_USE="200M"
JOURNAL_MAX_FILE="50M"

usage() {
cat <<'EOF'
Usage:
  sudo bash install.sh [options]

Options:
  --profile dev|prod            (default: dev)
  --admin-user <name>           (default: admin)
  --admin-pubkey "<ssh pubkey>" install authorized_keys
  --allow-password-ssh true|false
  --disable-cloud-init
  --timezone <TZ>
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2;;
    --admin-user) ADMIN_USER="$2"; shift 2;;
    --admin-pubkey) ADMIN_PUBKEY="$2"; shift 2;;
    --allow-password-ssh) ALLOW_PASSWORD_SSH="$2"; shift 2;;
    --disable-cloud-init) DISABLE_CLOUD_INIT="true"; shift 1;;
    --timezone) TIMEZONE="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "Unknown option: $1";;
  esac
done

require_root
ensure_ubuntu

log "=== Bootstrap start (profile=$PROFILE) ==="

source "$SCRIPT_DIR/scripts/05-precheck.sh"
source "$SCRIPT_DIR/scripts/10-init.sh"
source "$SCRIPT_DIR/scripts/20-admin-user.sh"
source "$SCRIPT_DIR/scripts/30-ssh.sh"
source "$SCRIPT_DIR/scripts/40-motd-banner.sh"

run_05_precheck

if [[ "$PROFILE" == "prod" ]]; then
  ALLOW_PASSWORD_SSH="false"
fi

run_10_init "$TIMEZONE" "$SWAP_MB" "$JOURNAL_MAX_USE" "$JOURNAL_MAX_FILE"
run_20_admin_user "$ADMIN_USER" "$ADMIN_SHELL" "$ADMIN_PUBKEY" "$SET_ADMIN_PASSWORD"
run_30_ssh "$ALLOW_PASSWORD_SSH"
run_40_motd_banner

if [[ "$DISABLE_CLOUD_INIT" == "true" ]]; then
  log "Disabling cloud-init"
  touch /etc/cloud/cloud-init.disabled
fi

log "=== Bootstrap done ==="
