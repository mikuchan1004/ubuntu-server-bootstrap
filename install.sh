#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/00-common.sh"

# Defaults
ADMIN_USER="admin"
ADMIN_SHELL="/bin/bash"
ADMIN_PUBKEY=""
ALLOW_PASSWORD_SSH="true"
SET_ADMIN_PASSWORD=""   # empty = no password change
TIMEZONE="Asia/Seoul"
PROFILE="dev"
DISABLE_CLOUD_INIT="false"

SWAP_MB="2048"
JOURNAL_MAX_USE="200M"
JOURNAL_MAX_FILE="50M"

ENABLE_FAIL2BAN="true"
ENABLE_UFW="true"
ENABLE_UNATTENDED_UPGRADES="true"

usage() {
cat <<'EOF'
Usage:
  sudo bash install.sh [options]

Options:
  --profile dev|prod            (default: dev)
  --admin-user <name>           (default: admin)
  --admin-pubkey "<ssh pubkey>" install authorized_keys for admin
  --allow-password-ssh true|false
  --set-admin-password "<pw>"   set admin password (optional)
  --disable-cloud-init
  --timezone <TZ>               (default: Asia/Seoul)

  --swap-mb <MB>                (default: 2048)
  --journal-max-use <SIZE>      (default: 200M)
  --journal-max-file <SIZE>     (default: 50M)

  --enable-fail2ban true|false
  --enable-ufw true|false
  --enable-unattended-upgrades true|false
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2;;
    --admin-user) ADMIN_USER="$2"; shift 2;;
    --admin-pubkey) ADMIN_PUBKEY="$2"; shift 2;;
    --allow-password-ssh) ALLOW_PASSWORD_SSH="$2"; shift 2;;
    --set-admin-password) SET_ADMIN_PASSWORD="$2"; shift 2;;
    --disable-cloud-init) DISABLE_CLOUD_INIT="true"; shift 1;;
    --timezone) TIMEZONE="$2"; shift 2;;

    --swap-mb) SWAP_MB="$2"; shift 2;;
    --journal-max-use) JOURNAL_MAX_USE="$2"; shift 2;;
    --journal-max-file) JOURNAL_MAX_FILE="$2"; shift 2;;

    --enable-fail2ban) ENABLE_FAIL2BAN="$2"; shift 2;;
    --enable-ufw) ENABLE_UFW="$2"; shift 2;;
    --enable-unattended-upgrades) ENABLE_UNATTENDED_UPGRADES="$2"; shift 2;;

    -h|--help) usage; exit 0;;
    *) die "Unknown option: $1";;
  esac
done

require_root
ensure_ubuntu
validate_bool "$ALLOW_PASSWORD_SSH" "allow-password-ssh"
validate_bool "$DISABLE_CLOUD_INIT" "disable-cloud-init"
validate_bool "$ENABLE_FAIL2BAN" "enable-fail2ban"
validate_bool "$ENABLE_UFW" "enable-ufw"
validate_bool "$ENABLE_UNATTENDED_UPGRADES" "enable-unattended-upgrades"

log "=== Bootstrap start (profile=$PROFILE) ==="

source "$SCRIPT_DIR/scripts/05-precheck.sh"
source "$SCRIPT_DIR/scripts/10-init.sh"
source "$SCRIPT_DIR/scripts/20-admin-user.sh"
source "$SCRIPT_DIR/scripts/30-ssh.sh"
source "$SCRIPT_DIR/scripts/40-motd-banner.sh"
source "$SCRIPT_DIR/scripts/50-fail2ban.sh"
source "$SCRIPT_DIR/scripts/60-ufw.sh"
source "$SCRIPT_DIR/scripts/70-unattended-upgrades.sh"

run_05_precheck

if [[ "$PROFILE" == "prod" ]]; then
  ALLOW_PASSWORD_SSH="false"
  # 잠금 사고 방지: 키가 없는데 비번까지 끄면 끝장
  [[ -n "$ADMIN_PUBKEY" ]] || die "prod 프로필에서는 --admin-pubkey가 필수입니다 (잠금 방지)"
fi

run_10_init "$TIMEZONE" "$SWAP_MB" "$JOURNAL_MAX_USE" "$JOURNAL_MAX_FILE"
run_20_admin_user "$ADMIN_USER" "$ADMIN_SHELL" "$ADMIN_PUBKEY" "$SET_ADMIN_PASSWORD"

# SSH는 마지막에, 그리고 reload/검증 후 적용 (세션 끊김 최소화)
run_30_ssh "$ALLOW_PASSWORD_SSH"

run_40_motd_banner

if [[ "$ENABLE_FAIL2BAN" == "true" ]]; then
  run_50_fail2ban
fi

if [[ "$ENABLE_UFW" == "true" ]]; then
  run_60_ufw_allow_ssh
fi

if [[ "$ENABLE_UNATTENDED_UPGRADES" == "true" ]]; then
  run_70_unattended_upgrades
fi

if [[ "$DISABLE_CLOUD_INIT" == "true" ]]; then
  log "Disabling cloud-init"
  touch /etc/cloud/cloud-init.disabled
fi

log "=== Bootstrap done ==="
