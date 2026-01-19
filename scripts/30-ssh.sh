#!/usr/bin/env bash
set -Eeuo pipefail
run_30_ssh(){
  local allow="$1"
  cat > /etc/ssh/sshd_config.d/99-zz-bootstrap.conf <<EOF
PubkeyAuthentication yes
PasswordAuthentication $allow
KbdInteractiveAuthentication $allow
UsePAM yes
PermitRootLogin no
EOF
  sshd -t || die "sshd invalid"
  systemctl restart ssh
}
