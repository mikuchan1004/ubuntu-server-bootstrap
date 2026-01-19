sudo tee /usr/local/sbin/setup-motd.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

# 기본 정적 motd는 끄고, update-motd로 관리
: > /etc/motd || true

MOTD_SCRIPT="/etc/update-motd.d/99-custom"

cat > "$MOTD_SCRIPT" <<'M'
#!/usr/bin/env bash
set -e

HOST="$(hostname)"
UPTIME="$(uptime -p 2>/dev/null || true)"
LOAD="$(cat /proc/loadavg 2>/dev/null | awk '{print $1" "$2" "$3}' || true)"
IP="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
DISK="$(df -h / 2>/dev/null | awk 'NR==2{print $4 " free / " $2 " total ("$5" used)"}' || true)"
MEM="$(free -h 2>/dev/null | awk '/Mem:/ {print $7 " avail / " $2 " total"}' || true)"
SWAP="$(free -h 2>/dev/null | awk '/Swap:/ {print $4 " free / " $2 " total"}' || true)"

echo
echo "🖥️  $HOST  |  IP: ${IP:-N/A}"
echo "⏱️  Uptime: ${UPTIME:-N/A}   |  Load: ${LOAD:-N/A}"
echo "💾 Disk (/): ${DISK:-N/A}"
echo "🧠 Mem: ${MEM:-N/A}   |  Swap: ${SWAP:-N/A}"
echo "🔐 Notice: Authorized use only."
echo
M

chmod +x "$MOTD_SCRIPT"
echo "[+] MOTD installed at $MOTD_SCRIPT"
EOF

sudo chmod +x /usr/local/sbin/setup-motd.sh
sudo /usr/local/sbin/setup-motd.sh
