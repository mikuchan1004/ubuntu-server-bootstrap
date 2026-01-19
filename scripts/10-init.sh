#!/usr/bin/env bash
set -Eeuo pipefail

run_10_init() {
  local timezone="$1"
  local swap_mb="$2"
  local journal_max_use="$3"
  local journal_max_file="$4"

  log "[10-init] Base packages & system settings"

  apt_install     ca-certificates curl wget gnupg lsb-release     vim tzdata ufw fail2ban     net-tools jq     unattended-upgrades apt-transport-https

  # Timezone
  log "[10-init] Set timezone: $timezone"
  timedatectl set-timezone "$timezone" || true

  # Unattended upgrades (safe defaults)
  log "[10-init] Enable unattended-upgrades"
  systemctl enable --now unattended-upgrades >/dev/null 2>&1 || true

  # journald limits
  log "[10-init] journald limits"
  write_file_root "/etc/systemd/journald.conf.d/99-limits.conf" "[Journal]
SystemMaxUse=${journal_max_use}
SystemMaxFileSize=${journal_max_file}
Compress=yes
Storage=persistent"
  systemctl restart systemd-journald || true

  # Swap (idempotent)
  if swapon --show | grep -q '^/swapfile'; then
    log "[10-init] Swapfile already present"
  else
    log "[10-init] Create swapfile: ${swap_mb}MB"
    fallocate -l "${swap_mb}M" /swapfile || dd if=/dev/zero of=/swapfile bs=1M count="$swap_mb"
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    ensure_line_in_file "/etc/fstab" "/swapfile none swap sw 0 0"
  fi

  # Memory tuning (safe)
  log "[10-init] sysctl tuning"
  write_file_root "/etc/sysctl.d/99-tuning.conf" "vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.somaxconn=1024"
  sysctl --system >/dev/null 2>&1 || true

  # UFW baseline (do NOT lock you out: allow SSH first)
  log "[10-init] UFW baseline"
  ufw allow 22/tcp >/dev/null 2>&1 || true
  ufw --force enable >/dev/null 2>&1 || true
  ufw logging low >/dev/null 2>&1 || true

  log "[10-init] Done"
}
