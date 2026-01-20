#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-common.sh"

run_30_ssh() {
  local allow_bool="$1"
  validate_bool "$allow_bool" "allow-password-ssh"

  # sshd_config는 true/false가 아니라 yes/no만 받음
  local allow="no"
  if [[ "$allow_bool" == "true" ]]; then
    allow="yes"
  fi

  log "[30] SSH hardening (PasswordAuth=${allow_bool} -> ${allow})"

  install -d -m 0755 /etc/ssh/sshd_config.d
  local conf="/etc/ssh/sshd_config.d/99-zz-bootstrap.conf"
  backup_file "$conf"

  cat > "$conf" <<EOFCONF
# Managed by ubuntu-server-bootstrap
PubkeyAuthentication yes
PasswordAuthentication ${allow}
KbdInteractiveAuthentication ${allow}
UsePAM yes

PermitRootLogin no
X11Forwarding no

ClientAliveInterval 300
ClientAliveCountMax 2
EOFCONF

  sshd -t || die "sshd config invalid (refusing to apply)"

  # restart 대신 reload 우선 (세션 끊김 확률 줄임)
  if systemctl is-active --quiet ssh; then
    systemctl reload ssh || systemctl restart ssh
  else
    systemctl restart ssh
  fi

  log "[30] OK"
}
