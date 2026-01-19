#!/usr/bin/env bash
set -euo pipefail

HOST="$(hostname)"
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"

UPTIME="$(uptime -p | sed 's/^up //')"
LOAD="$(awk '{print $1" "$2" "$3}' /proc/loadavg)"

DISK_LINE="$(df -h / 2>/dev/null | awk 'NR==2{print $4" free / "$2" total ("$5" used)"}')"

MEM_TOTAL="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)"
MEM_AVAIL="$(awk '/MemAvailable/ {print int($2/1024)}' /proc/meminfo)"

SWAP_TOTAL_K="$(awk '/SwapTotal/ {print $2}' /proc/meminfo)"
SWAP_FREE_K="$(awk '/SwapFree/ {print $2}' /proc/meminfo)"
swap_gib() { awk -v k="$1" 'BEGIN{printf "%.1f", k/1024/1024}'; }

SWAP_TOTAL="$(swap_gib "$SWAP_TOTAL_K")"
SWAP_FREE="$(swap_gib "$SWAP_FREE_K")"

cat <<EOF

🖥️  ${HOST}  |  IP: ${IP:-N/A}
⏱️  Uptime: up ${UPTIME}   |  Load: ${LOAD}
💾 Disk (/): ${DISK_LINE}
🧠 Mem: ${MEM_AVAIL}Mi avail / ${MEM_TOTAL}Mi total   |  Swap: ${SWAP_FREE}Gi free / ${SWAP_TOTAL}Gi total
🔐 Notice: Authorized use only.

EOF
