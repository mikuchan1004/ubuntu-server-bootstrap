#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Ubuntu Server Bootstrap - Installer (idempotent)
# Repo: mikuchan1004/ubuntu-server-bootstrap
# ============================================================
#
# Usage:
#   sudo bash install.sh
#
# Optional env:
#   REPO_URL   (default: https://github.com/mikuchan1004/ubuntu-server-bootstrap.git)
#   BRANCH     (default: main)
#   INSTALL_DIR(default: /opt/ubuntu-server-bootstrap)
#
#   TIMEZONE   (default: Asia/Seoul)
#   LOCALE     (default: ko_KR.UTF-8)
#   KEEP_MESSAGES_EN (default: 1)  # sets LC_MESSAGES=C
#
#   SWAP_SIZE  (default: 2G)      # "0" disables swap creation
#   JOURNAL_MAX_USE (default: 200M)
#   JOURNAL_RUNTIME_MAX_USE (default: 50M)
#
#   SSH_PASSWORD_AUTH (default: yes)  # yes/no
#   ADMIN_USER (optional)             # e.g. admin
#   ADMIN_PUBKEY (optional)           # e.g. "ssh-ed25519 AAAA..."
#   ADMIN_PASSWORD (optional)         # sets password non-interactively (use carefully)
# ============================================================

REPO_URL="${REPO_URL:-https://github.com/mikuchan1004/ubuntu-server-bootstrap.git}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-/opt/ubuntu-server-bootstrap}"

LOG_DIR="/var/log/ubuntu-server-bootstrap"
TS="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/install-$TS.log"

msg()  { echo "[*] $*"; }
ok()   { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[-] $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1; }

on_error() {
  local code=$?
  warn "Installer failed (exit=$code)"
  warn "Log: $LOG_FILE"
  exit "$code"
}
trap on_error ERR

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  need sudo || die "sudo not found. Run as root."
  msg "Re-running with sudo..."
  exec sudo -E bash "$0"
fi

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

msg "Ubuntu Server Bootstrap installer"
msg "Repo   : $REPO_URL"
msg "Branch : $BRANCH"
msg "Dir    : $INSTALL_DIR"
msg "Log    : $LOG_FILE"

[[ -r /etc/os-release ]] || die "/etc/os-release not found"
. /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || die "Unsupported OS: ${ID:-unknown}"
ok "OS: ${PRETTY_NAME:-Ubuntu}"

export DEBIAN_FRONTEND=noninteractive

msg "Updating apt cache..."
apt-get update -y

for pkg in git ca-certificates curl; do
  if ! need "$pkg"; then
    msg "Installing $pkg..."
    apt-get install -y "$pkg"
  fi
done
ok "Dependencies ready"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  msg "Updating existing repository..."
  git -C "$INSTALL_DIR" fetch origin
  git -C "$INSTALL_DIR" checkout "$BRANCH"
  git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH"
else
  msg "Cloning repository..."
  mkdir -p "$INSTALL_DIR"
  git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$INSTALL_DIR"
fi
ok "Repository ready"

SCRIPTS="$INSTALL_DIR/scripts"
[[ -d "$SCRIPTS" ]] || die "Missing scripts directory: $SCRIPTS"

required=(
  init-ubuntu-server.sh
  setup-login-banner.sh
  setup-motd.sh
  create-admin-user.sh
)

for f in "${required[@]}"; do
  [[ -f "$SCRIPTS/$f" ]] || die "Missing script: $SCRIPTS/$f"
done

msg "Normalizing scripts (CRLF->LF) and chmod +x..."
for f in "${required[@]}"; do
  sed -i 's/\r$//' "$SCRIPTS/$f"
  chmod +x "$SCRIPTS/$f"
done
ok "Scripts ready"

msg "1/3 init-ubuntu-server.sh"
bash "$SCRIPTS/init-ubuntu-server.sh"

msg "2/3 setup-login-banner.sh"
bash "$SCRIPTS/setup-login-banner.sh"

msg "3/3 setup-motd.sh"
bash "$SCRIPTS/setup-motd.sh"

if [[ -n "${ADMIN_USER:-}" ]]; then
  msg "Ensuring admin user: $ADMIN_USER"
  if [[ -n "${ADMIN_PUBKEY:-}" ]]; then
    bash "$SCRIPTS/create-admin-user.sh" "$ADMIN_USER" "$ADMIN_PUBKEY"
  else
    bash "$SCRIPTS/create-admin-user.sh" "$ADMIN_USER"
  fi
  ok "Admin user ensured: $ADMIN_USER"
fi

ok "Bootstrap completed successfully"
msg "Tip: reconnect SSH to see banner/MOTD changes clearly."
msg "Log saved: $LOG_FILE"
