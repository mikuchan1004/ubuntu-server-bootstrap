#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/00-common.sh"

run_50_fail2ban() {
  log "[50] Fail2Ban"

  command -v fail2ban-client >/dev/null 2>&1 || {
    warn "fail2ban-client not found (package missing?)"
    return 0
  }

  install -d -m 0755 /etc/fail2ban

  backup_file /etc/fail2ban/jail.local
  cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled = true
bantime = 1h
findtime = 10m
maxretry = 5
backend = systemd
EOF

  systemctl enable --now fail2ban
  systemctl restart fail2ban || true

  log "[50] OK"
}
