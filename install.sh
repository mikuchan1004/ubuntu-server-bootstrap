#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# Ubuntu Server Bootstrap - Installer
# Repo   : https://github.com/mikuchan1004/ubuntu-server-bootstrap
# Author : mikuchan1004
# ============================================================

# ---------- configurable (env override) ----------
REPO_URL="${REPO_URL:-https://github.com/mikuchan1004/ubuntu-server-bootstrap.git}"
BRANCH="${BRANCH:-main}"
INSTALL_DIR="${INSTALL_DIR:-/opt/ubuntu-server-bootstrap}"

# Optional admin creation
ADMIN_USER="${ADMIN_USER:-}"
ADMIN_PUBKEY="${ADMIN_PUBKEY:-}"

# ---------- runtime ----------
LOG_DIR="/var/log/ubuntu-server-bootstrap"
TS="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/install-$TS.log"

# ---------- helpers ----------
msg()  { echo "[*] $*"; }
ok()   { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[-] $*" >&2; exit 1; }

on_error() {
  local code=$?
  warn "Installer failed (exit=$code)"
  warn "Check log: $LOG_FILE"
  exit "$code"
}
trap on_error ERR

need() { command -v "$1" >/dev/null 2>&1; }

# ---------- root guard ----------
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  need sudo || die "sudo not found. Run as root."
  msg "Re-running with sudo..."
  exec sudo -E bash "$0"
fi

# ---------- logging ----------
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

msg "Ubuntu Server Bootstrap installer"
msg "Repo   : $REPO_URL"
msg "Branch : $BRANCH"
msg "Dir    : $INSTALL_DIR"
msg "Log    : $LOG_FILE"

# ---------- OS check ----------
[[ -r /etc/os-release ]] || die "/etc/os-release not found"
. /etc/os-release
[[ "${ID:-}" == "ubuntu" ]] || die "Unsupported OS: ${ID:-unknown}"

ok "OS check passed (${PRETTY_NAME:-Ubuntu})"

# ---------- apt sanity ----------
export DEBIAN_FRONTEND=noninteractive
msg "Updating apt cache..."
apt-get update -y

# ---------- dependencies ----------
for pkg in git ca-certificates curl; do
  if ! need "$pkg"; then
    msg "Installing $pkg..."
    apt-get install -y "$pkg"
  fi
done
ok "Dependencies ready"

# ---------- clone or update ----------
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

# ---------- validate scripts ----------
SCRIPTS="$INSTALL_DIR/scripts"
REQUIRED=(
  init-ubuntu-server.sh
  setup-login-banner.sh
  setup-motd.sh
  create-admin-user.sh
)

[[ -d "$SCRIPTS" ]] || die "scripts/ directory missing"

for f in "${REQUIRED[@]}"; do
  [[ -f "$SCRIPTS/$f" ]] || die "Missing script: $f"
done
ok "All scripts verified"

# ---------- normalize scripts ----------
msg "Normalizing scripts (CRLF/LF + chmod)..."
for f in "${REQUIRED[@]}"; do
  sed -i 's/\r$//' "$SCRIPTS/$f"
  chmod +x "$SCRIPTS/$f"
done
ok "Scripts normalized"

# ---------- execution ----------
msg "Running init-ubuntu-server.sh"
bash "$SCRIPTS/init-ubuntu-server.sh"

msg "Running setup-login-banner.sh"
bash "$SCRIPTS/setup-login-banner.sh"

msg "Running setup-motd.sh"
bash "$SCRIPTS/setup-motd.sh"

# ---------- optional admin ----------
if [[ -n "$ADMIN_USER" ]]; then
  msg "Creating admin user: $ADMIN_USER"
  if [[ -n "$ADMIN_PUBKEY" ]]; then
    bash "$SCRIPTS/create-admin-user.sh" "$ADMIN_USER" "$ADMIN_PUBKEY"
  else
    bash "$SCRIPTS/create-admin-user.sh" "$ADMIN_USER"
  fi
  ok "Admin user ensured: $ADMIN_USER"
fi

# ---------- done ----------
ok "Bootstrap completed successfully"
msg "Reconnect SSH to fully apply banner/MOTD changes"
msg "Log saved at: $LOG_FILE"
