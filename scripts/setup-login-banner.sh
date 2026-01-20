#!/usr/bin/env bash
set -Eeuo pipefail

msg()  { echo "[*] $*"; }
ok()   { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[-] $*"; exit 1; }

trap 'warn "setup-login-banner.sh failed"; exit 1' ERR
[[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root (use sudo)."

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)"
ISSUE_NET_SRC="$TEMPLATE_DIR/issue.net"
ISSUE_NET_DST="/etc/issue.net"

msg "Installing /etc/issue.net banner..."
if [[ -f "$ISSUE_NET_SRC" ]]; then
  install -m 0644 "$ISSUE_NET_SRC" "$ISSUE_NET_DST"
else
  cat > "$ISSUE_NET_DST" <<'EOF'
********************************************************************
*  WARNING: Authorized access only.                               *
*                                                                  *
*  All activity may be monitored and recorded.                     *
*  Disconnect immediately if you are not an authorized user.       *
********************************************************************
EOF
  chmod 0644 "$ISSUE_NET_DST"
fi

msg "Enabling SSH banner..."
cat > /etc/ssh/sshd_config.d/98-banner.conf <<'EOF'
Banner /etc/issue.net
EOF
chmod 0644 /etc/ssh/sshd_config.d/98-banner.conf

sshd -t
systemctl restart ssh
ok "Login banner configured"
