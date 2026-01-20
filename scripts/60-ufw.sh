#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-common.sh"

run_60_ufw_allow_ssh() {
  log "[60] UFW"

  command -v ufw >/dev/null 2>&1 || { warn "ufw not found"; return 0; }

  # SSH 먼저 허용
  ufw allow OpenSSH >/dev/null || true

  # 기본정책
  ufw default deny incoming >/dev/null || true
  ufw default allow outgoing >/dev/null || true

  # enable (이미 enabled면 no-op)
  ufw --force enable >/dev/null || true

  log "[60] OK"
}
