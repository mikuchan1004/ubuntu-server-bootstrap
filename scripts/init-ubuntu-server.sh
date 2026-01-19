sudo tee /usr/local/sbin/init-ubuntu-server.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

# =====================================================
# Ubuntu Server Initial Setup (Final - Operation Ready)
#
# ✔ Timezone: Asia/Seoul
# ✔ Locale: ko_KR.UTF-8 (messages kept in English)
# ✔ SSH hardening (NO key-only enforcement)
# ✔ Swap (2G) + memory tuning
# ✔ journald log size limit
# ✔ UFW + Fail2ban
#
# Safe for real servers (password login kept)
# =====================================================

# ---------- root check ----------
if [[ $EUID -ne 0 ]]; then
  echo "[-] Run as root: sudo init-ubuntu-server.sh"
  exit 1
fi

log() { echo "[*] $*"; }
ok()  { echo "[+] $*"; }

# ---------- base packages ----------
log "apt update"
apt update -y

log "install base utilities"
apt install -y \
  curl wget git ca-certificates gnupg lsb-release \
  htop tmux vim nano unzip zip \
  net-tools dnsutils \
  software-properties-common \
  locales

# ---------- timezone ----------
log "set timezone: Asia/Seoul"
timedatectl set-timezone Asia/Seoul
ok "timezone set"

# ---------- locale ----------
log "configure locale: ko_KR.UTF-8"
apt install -y language-pack-ko || true
sed -i 's/^[# ]*\(ko_KR\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
update-locale LANG=ko_KR.UTF-8 LC_ALL=ko_KR.UTF-8

# keep messages in English (better for googling errors)
cat > /etc/profile.d/00-locale.sh <<'EOP'
export LANG=ko_KR.UTF-8
export LC_ALL=ko_KR.UTF-8
export LC_MESSAGES=C
EOP
chmod 644 /etc/profile.d/00-locale.sh

# ---------- fonts (safe even on servers) ----------
log "install Korean fonts"
apt install -y fonts-nanum fonts-noto-cjk || true
fc-cache -f -v >/dev/null 2>&1 || true

# ---------- SSH hardening (no key-only lockout) ----------
log "apply SSH hardening"
apt install -y openssh-server

SSHD_DIR="/etc/ssh/sshd_config.d"
mkdir -p "$SSHD_DIR"

cat > "$SSHD_DIR/99-hardening.conf" <<'EOP'
# Managed by init-ubuntu-server.sh
PermitRootLogin no
MaxAuthTries 4
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
UseDNS no
X11Forwarding no
AllowTcpForwarding no
KbdInteractiveAuthentication no
EOP

if sshd -t; then
  systemctl restart ssh || systemctl restart sshd
  ok "sshd restarted"
else
  echo "[-] sshd config error, aborting"
  exit 1
fi

# ---------- swap ----------
log "configure swap (2G)"
SWAPFILE="/swapfile"
if ! swapon --show | grep -q "$SWAPFILE"; then
  if ! [[ -f "$SWAPFILE" ]]; then
    fallocate -l 2G "$SWAPFILE" || dd if=/dev/zero of="$SWAPFILE" bs=1M count=2048
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE" >/dev/null
  fi
  swapon "$SWAPFILE"
  grep -q '/swapfile' /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi
ok "swap active"

# ---------- memory tuning ----------
log "apply sysctl tuning"
cat > /etc/sysctl.d/99-tuning.conf <<'EOP'
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOP
sysctl --system >/dev/null

# ---------- journald limits ----------
log "limit journald size"
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-limits.conf <<'EOP'
[Journal]
SystemMaxUse=500M
SystemMaxFileSize=100M
MaxRetentionSec=14day
Compress=yes
EOP
systemctl restart systemd-journald

# ---------- firewall + fail2ban ----------
log "enable UFW + Fail2ban"
apt install -y ufw fail2ban
ufw allow OpenSSH >/dev/null
ufw --force enable >/dev/null

cat > /etc/fail2ban/jail.d/sshd.local <<'EOP'
[sshd]
enabled = true
maxretry = 5
findtime = 10m
bantime  = 1h
EOP
systemctl enable --now fail2ban >/dev/null

# ---------- cleanup ----------
log "cleanup"
apt autoremove -y
apt clean

echo
ok "ALL DONE"
echo "➡ SSH 재접속 권장 (reboot 불필요)"
echo
echo "확인:"
echo "  timedatectl"
echo "  locale"
echo "  swapon --show"
echo "  journalctl --disk-usage"
echo "  fail2ban-client status sshd"
echo "  sshd -T | egrep 'permitrootlogin|maxauthtries'"
EOF

sudo chmod +x /usr/local/sbin/init-ubuntu-server.sh
echo "✔ saved to /usr/local/sbin/init-ubuntu-server.sh"
