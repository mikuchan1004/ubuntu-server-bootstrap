#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-common.sh"

run_30_ssh() {
  local allow_password="$1"
  validate_bool "$allow_password" "allow-password-ssh"

  log "[30] SSH hardening (PasswordAuth=$allow_password)"

  # /etc/ssh/sshd_config.d 사용 (Ubuntu 기본)
  install -d -m 0755 /etc/ssh/sshd_config.d

  # 안전장치: 비번 끌 때는 퍼블릭키 인증이 켜져 있어야 함
  local conf="/etc/ssh/sshd_config.d/99-zz-bootstrap.conf"
  backup_file "$conf"

  cat > "$conf" <<EOF
# Managed by ubuntu-server-bootstrap
PubkeyAuthentication yes
PasswordAuthentication ${allow_password}
KbdInteractiveAuthentication ${allow_password}
UsePAM yes

PermitRootLogin no
X11Forwarding no
AllowTcpForwarding yes
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

  # sshd config test
  sshd -t || die "sshd config invalid (refusing to apply)"

  # reload (restart보다 덜 위험)
  if systemctl is-active --quiet ssh; then
    systemctl reload ssh || systemctl restart ssh
  else
    systemctl restart ssh
  fi

  log "[30] OK"
}
