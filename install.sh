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
  --admin-pubkey "<ssh pubkey>" (optional) install/replace admin authorized_keys
  --allow-password-ssh true|false
  --set-admin-password "<pw>"   (optional)
  --disable-cloud-init
  --timezone <TZ>

  --swap-mb <MB>
  --journal-max-use <SIZE>
  --journal-max-file <SIZE>

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
# (있으면) 추가 스크립트들
[[ -f "$SCRIPT_DIR/scripts/50-fail2ban.sh" ]] && source "$SCRIPT_DIR/scripts/50-fail2ban.sh"
[[ -f "$SCRIPT_DIR/scripts/60-ufw.sh" ]] && source "$SCRIPT_DIR/scripts/60-ufw.sh"
[[ -f "$SCRIPT_DIR/scripts/70-unattended-upgrades.sh" ]] && source "$SCRIPT_DIR/scripts/70-unattended-upgrades.sh"

run_05_precheck
run_10_init "$TIMEZONE" "$SWAP_MB" "$JOURNAL_MAX_USE" "$JOURNAL_MAX_FILE"

# 1) admin 유저/키부터 정리 (prod 잠금사고 방지의 핵심)
run_20_admin_user "$ADMIN_USER" "$ADMIN_SHELL" "$ADMIN_PUBKEY" "$SET_ADMIN_PASSWORD"

# 2) prod면: 비번 SSH 끄기 전에 "admin 키 존재"를 반드시 확인 (C 루트)
if [[ "$PROFILE" == "prod" ]]; then
  ALLOW_PASSWORD_SSH="false"

  ADMIN_AUTH="/home/${ADMIN_USER}/.ssh/authorized_keys"
  if [[ ! -s "$ADMIN_AUTH" ]]; then
    die "prod 프로필: ${ADMIN_AUTH} 가 비어있거나 없습니다. (잠금 방지) --admin-pubkey로 키를 넣거나, 파일을 먼저 준비하세요."
  fi

  log "prod check OK: admin authorized_keys present"
fi

# 3) SSH 적용 (검증 + reload는 30-ssh.sh에서)
run_30_ssh "$ALLOW_PASSWORD_SSH"

run_40_motd_banner

if [[ "$ENABLE_FAIL2BAN" == "true" ]] && declare -F run_50_fail2ban >/dev/null; then
  run_50_fail2ban
fi
if [[ "$ENABLE_UFW" == "true" ]] && declare -F run_60_ufw_allow_ssh >/dev/null; then
  run_60_ufw_allow_ssh
fi
if [[ "$ENABLE_UNATTENDED_UPGRADES" == "true" ]] && declare -F run_70_unattended_upgrades >/dev/null; then
  run_70_unattended_upgrades
fi

if [[ "$DISABLE_CLOUD_INIT" == "true" ]]; then
  log "Disabling cloud-init"
  touch /etc/cloud/cloud-init.disabled
fi

log "=== Bootstrap done ==="
