cat > templates/motd-99-custom.sh <<'EOF'
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
EOF
