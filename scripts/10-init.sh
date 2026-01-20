#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-common.sh"

run_10_init() {
  local tz="$1" swap_mb="$2" journal_use="$3" journal_file="$4"
  log "[10] Init (timezone/swap/journald)"

  # timezone
  if command -v timedatectl >/dev/null 2>&1; then
    timedatectl set-timezone "$tz" || warn "Failed to set timezone: $tz"
  fi

  # packages baseline
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y
  apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg lsb-release \
    ufw fail2ban unattended-upgrades \
    sudo

  # swap (idempotent)
  if ! swapon --show | grep -q '^/swapfile'; then
    log "Creating /swapfile (${swap_mb}MB)"
    fallocate -l "${swap_mb}M" /swapfile || dd if=/dev/zero of=/swapfile bs=1M count="$swap_mb"
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  else
    log "Swap already enabled"
  fi

  # journald limits
  backup_file /etc/systemd/journald.conf
  {
    echo "[Journal]"
    echo "SystemMaxUse=${journal_use}"
    echo "SystemMaxFileSize=${journal_file}"
  } | write_file_atomic /etc/systemd/journald.conf 0644

  systemctl restart systemd-journald || true

  log "[10] OK"
}
