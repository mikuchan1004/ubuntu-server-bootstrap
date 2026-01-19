#!/usr/bin/env bash
set -Eeuo pipefail
LOG_FILE="/var/log/ubuntu-server-bootstrap.log"
log(){ echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE" >&2; }
die(){ log "ERROR: $*"; exit 1; }
require_root(){ [[ $EUID -eq 0 ]] || die "Run as root"; }
ensure_ubuntu(){ . /etc/os-release; [[ "$ID" == "ubuntu" ]] || die "Ubuntu only"; }
cmd_exists(){ command -v "$1" >/dev/null 2>&1; }
