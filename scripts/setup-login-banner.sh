sudo tee /usr/local/sbin/setup-login-banner.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

BANNER_FILE="/etc/issue.net"
SSHD_DROPIN="/etc/ssh/sshd_config.d/98-banner.conf"

cat > "$BANNER_FILE" <<'B'
********************************************************************
*  WARNING: Authorized access only.                               *
*                                                                  *
*  All activity may be monitored and recorded.                     *
*  Disconnect immediately if you are not an authorized user.       *
********************************************************************
B

mkdir -p /etc/ssh/sshd_config.d
cat > "$SSHD_DROPIN" <<EOC
# Managed by setup-login-banner.sh
Banner $BANNER_FILE
EOC

if sshd -t; then
  systemctl restart ssh || systemctl restart sshd
  echo "[+] SSH pre-login banner enabled."
else
  echo "[-] sshd config validation failed."
  exit 1
fi
EOF

sudo chmod +x /usr/local/sbin/setup-login-banner.sh
sudo /usr/local/sbin/setup-login-banner.sh
