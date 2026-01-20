#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-common.sh"

run_05_precheck() {
  log "[05] Precheck"

  # SSH 연결 환경 확인(원격에서 돌릴 때)
  if [[ -n "${SSH_CLIENT:-}" ]]; then
    log "SSH detected: ${SSH_CLIENT%% *}"
  else
    warn "SSH_CLIENT not set (console/local?)"
  fi

  command -v apt-get >/dev/null 2>&1 || die "apt-get not found"
  command -v systemctl >/dev/null 2>&1 || die "systemctl not found"

  # 네트워크 최소 체크
  if ! timeout 2 ping -c 1 1.1.1.1 >/dev/null 2>&1; then
    warn "Network ping failed (apt may fail)"
  fi

  log "[05] OK"
}
