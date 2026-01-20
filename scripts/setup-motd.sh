#!/usr/bin/env bash
set -Eeuo pipefail

msg()  { echo "[*] $*"; }
ok()   { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[-] $*"; exit 1; }

trap 'warn "setup-motd.sh failed"; exit 1' ERR
[[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root (use sudo)."

TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../templates" && pwd)"
MOTD_SRC="$TEMPLATE_DIR/motd-99-custom.sh"
MOTD_DST="/etc/update-motd.d/99-ubuntu-server-bootstrap"

msg "Installing MOTD script..."
install -m 0755 "$MOTD_SRC" "$MOTD_DST"

if [[ -f /etc/default/motd-news ]]; then
  sed -i 's/^[# ]*ENABLED=.*/ENABLED=0/' /etc/default/motd-news || true
fi

ok "MOTD configured (reconnect SSH to see it)"
