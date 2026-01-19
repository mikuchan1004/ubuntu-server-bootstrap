#!/usr/bin/env bash
set -Eeuo pipefail
run_05_precheck(){
  log "[precheck] sshd syntax"
  sshd -t || die "sshd config invalid"
  log "[precheck] ssh active"
  systemctl is-active --quiet ssh || die "ssh not running"
  log "[precheck] port 22 listening"
  ss -lnt | grep -q ':22 ' || die "22 not listening"
}
