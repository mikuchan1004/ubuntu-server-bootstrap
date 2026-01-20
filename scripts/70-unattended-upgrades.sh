#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-common.sh"

run_70_unattended_upgrades() {
  log "[70] Unattended upgrades"

  command -v unattended-upgrade >/dev/null 2>&1 || {
    warn "unattended-upgrades not found"
    return 0
  }

  dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null 2>&1 || true
  systemctl enable --now unattended-upgrades >/dev/null 2>&1 || true

  log "[70] OK"
}
