#!/usr/bin/env bash
set -Eeuo pipefail

run_40_motd_banner() {
  log "[40-motd] Setup banner & motd"

  # SSH Banner
  write_file_root "/etc/issue.net" "********************************************************************
*  WARNING: Authorized access only.                               *
*                                                                  *
*  All activity may be monitored and recorded.                     *
*  Disconnect immediately if you are not an authorized user.       *
********************************************************************"

  # Enable Banner in sshd drop-in
  write_file_root "/etc/ssh/sshd_config.d/98-banner.conf" "# Managed by ubuntu-server-bootstrap
Banner /etc/issue.net"

  sshd -t || die "sshd config test failed after banner change"
  systemctl restart ssh

  # Dynamic MOTD
  write_file_root "/etc/update-motd.d/99-custom" "#!/usr/bin/env bash
set -e

HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')
UP=$(uptime -p 2>/dev/null || true)
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)
DISK=$(df -h / | awk 'NR==2{print $4" free / "$2" total ("$5" used)"}')
MEM=$(free -m | awk '/Mem:/ {print $7"Mi avail / "$2"Mi total"}')
SWP=$(free -h | awk '/Swap:/ {print $4" free / "$2" total"}')

echo ""
echo "🖥️  $HOST  |  IP: $IP"
echo "⏱️  Uptime: $UP   |  Load: $LOAD"
echo "💾 Disk (/): $DISK"
echo "🧠 Mem: $MEM   |  Swap: $SWP"
echo "🔐 Notice: Authorized use only."
echo ""
"
  chmod +x /etc/update-motd.d/99-custom

  log "[40-motd] Done"
}
