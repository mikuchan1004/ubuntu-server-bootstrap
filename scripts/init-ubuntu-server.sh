#!/usr/bin/env bash
set -Eeuo pipefail

msg()  { echo "[*] $*"; }
ok()   { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }
die()  { echo "[-] $*"; exit 1; }

trap 'warn "init-ubuntu-server.sh failed"; exit 1' ERR

[[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Run as root (use sudo)."

export DEBIAN_FRONTEND=noninteractive

TIMEZONE="${TIMEZONE:-Asia/Seoul}"
LOCALE="${LOCALE:-ko_KR.UTF-8}"
KEEP_MESSAGES_EN="${KEEP_MESSAGES_EN:-1}"

SWAP_SIZE="${SWAP_SIZE:-2G}"
JOURNAL_MAX_USE="${JOURNAL_MAX_USE:-200M}"
JOURNAL_RUNTIME_MAX_USE="${JOURNAL_RUNTIME_MAX_USE:-50M}"

SSH_PASSWORD_AUTH="${SSH_PASSWORD_AUTH:-yes}"

msg "Installing baseline packages..."
apt-get update -y
apt-get install -y --no-install-recommends \
  locales tzdata \
  ufw fail2ban \
  curl ca-certificates \
  git \
  openssh-server \
  coreutils procps

ok "Packages ready"

msg "Setting timezone: $TIMEZONE"
timedatectl set-timezone "$TIMEZONE" || true
ok "Timezone set"

msg "Configuring locale: $LOCALE"
if ! locale -a | grep -qi "^${LOCALE}$"; then
  if ! grep -qE "^[# ]*${LOCALE}[[:space:]]+UTF-8" /etc/locale.gen; then
    echo "${LOCALE} UTF-8" >> /etc/locale.gen
  else
    sed -i "s/^[# ]*${LOCALE}[[:space:]]\+UTF-8/${LOCALE} UTF-8/" /etc/locale.gen
  fi
  locale-gen "$LOCALE"
fi

update-locale LANG="$LOCALE"
if [[ "$KEEP_MESSAGES_EN" == "1" ]]; then
  update-locale LC_MESSAGES=C
fi
ok "Locale configured"

if [[ "$SWAP_SIZE" != "0" ]]; then
  msg "Ensuring swap exists (size: $SWAP_SIZE)"
  if swapon --show | grep -q .; then
    ok "Swap already enabled"
  else
    if [[ ! -f /swapfile ]]; then
      if command -v fallocate >/dev/null 2>&1; then
        fallocate -l "$SWAP_SIZE" /swapfile
      else
        dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
      fi
      chmod 600 /swapfile
      mkswap /swapfile
    fi
    swapon /swapfile
    grep -qE '^/swapfile[[:space:]]' /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
    ok "Swap enabled"
  fi
else
  msg "SWAP_SIZE=0 (swap creation disabled)"
fi

msg "Applying sysctl tuning..."
cat > /etc/sysctl.d/99-ubuntu-server-bootstrap.conf <<'EOF'
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF
sysctl --system >/dev/null 2>&1 || true
ok "Sysctl tuned"

msg "Limiting journald size..."
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-ubuntu-server-bootstrap.conf <<EOF
[Journal]
SystemMaxUse=${JOURNAL_MAX_USE}
RuntimeMaxUse=${JOURNAL_RUNTIME_MAX_USE}
Compress=yes
EOF
systemctl restart systemd-journald
ok "journald configured"

msg "Configuring UFW..."
ufw --force reset || true
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw --force enable
ok "UFW enabled"

msg "Configuring Fail2ban..."
mkdir -p /etc/fail2ban/jail.d
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
maxretry = 5
findtime = 10m
bantime  = 1h
EOF
systemctl enable --now fail2ban
ok "Fail2ban enabled"

msg "Configuring SSH (root login off + auth policy override)..."
cat > /etc/ssh/sshd_config.d/99-hardening.conf <<'EOF'
PermitRootLogin no
PubkeyAuthentication yes
UsePAM yes
X11Forwarding no
AllowTcpForwarding yes
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

AUTH_FILE="/etc/ssh/sshd_config.d/999-auth-policy.conf"
if [[ "${SSH_PASSWORD_AUTH,,}" == "no" ]]; then
  cat > "$AUTH_FILE" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
EOF
else
  cat > "$AUTH_FILE" <<'EOF'
PasswordAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
EOF
fi
chmod 644 "$AUTH_FILE"

if [[ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]]; then
  sed -i 's/^[[:space:]]*PasswordAuthentication[[:space:]]\+no/#PasswordAuthentication no/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf || true
  sed -i 's/^[[:space:]]*KbdInteractiveAuthentication[[:space:]]\+no/#KbdInteractiveAuthentication no/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf || true
fi

sshd -t
systemctl restart ssh
ok "SSH configured"

ok "Base initialization completed"
