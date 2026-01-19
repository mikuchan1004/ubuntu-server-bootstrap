#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="/var/log/ubuntu-server-bootstrap.log"

log() {
  local msg="$*"
  echo "[$(date '+%F %T')] $msg" | tee -a "$LOG_FILE" >&2
}

die() {
  log "ERROR: $*"
  exit 1
}

require_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root: sudo bash install.sh"
}

ensure_ubuntu() {
  [[ -f /etc/os-release ]] || die "/etc/os-release not found"
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "ubuntu" ]] || die "This script supports Ubuntu only. Detected: ${ID:-unknown}"
}

apt_install() {
  export DEBIAN_FRONTEND=noninteractive
  log "apt-get update"
  apt-get update -y
  log "apt-get install: $*"
  apt-get install -y --no-install-recommends "$@"
}

ensure_line_in_file() {
  local file="$1" line="$2"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

write_file_root() {
  local path="$1"
  shift
  install -d -m 0755 "$(dirname "$path")"
  cat > "$path" <<EOF
$*
EOF
}

backup_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  cp -a "$f" "${f}.bak.$(date +%s)"
}
