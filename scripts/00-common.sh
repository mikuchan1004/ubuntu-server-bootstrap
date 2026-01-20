#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
warn() { printf '[%s] ⚠ %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }
die() { printf '[%s] ❌ %s\n' "$(date '+%H:%M:%S')" "$*" >&2; exit 1; }

require_root() {
  [[ "$(id -u)" -eq 0 ]] || die "Run as root (sudo)"
}

ensure_ubuntu() {
  [[ -r /etc/os-release ]] || die "Cannot read /etc/os-release"
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "ubuntu" ]] || die "Ubuntu only (detected: ${ID:-unknown})"
}

validate_bool() {
  local v="$1" name="$2"
  [[ "$v" == "true" || "$v" == "false" ]] || die "$name must be true|false (got: $v)"
}

backup_file() {
  local path="$1"
  [[ -e "$path" ]] || return 0
  local ts; ts="$(date '+%Y%m%d_%H%M%S')"
  cp -a "$path" "${path}.bak.${ts}"
}

# 원자적 파일 쓰기: temp -> move
write_file_atomic() {
  local path="$1"
  local mode="$2"
  local tmp; tmp="$(mktemp)"
  cat > "$tmp"
  install -m "$mode" "$tmp" "$path"
  rm -f "$tmp"
}
