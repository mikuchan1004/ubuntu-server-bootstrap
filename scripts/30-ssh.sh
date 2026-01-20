run_30_ssh() {
  local allow="${1:-true}"

  # normalize to yes/no for OpenSSH
  local yn
  case "$allow" in
    true|yes|on|1) yn="yes" ;;
    false|no|off|0) yn="no" ;;
    *) die "run_30_ssh: allow must be true|false (got: $allow)" ;;
  esac

  install -d -m 0755 /etc/ssh/sshd_config.d

  cat > /etc/ssh/sshd_config.d/99-zz-bootstrap.conf <<EOF
# Managed by ubuntu-server-bootstrap
PubkeyAuthentication yes
PasswordAuthentication $yn
KbdInteractiveAuthentication $yn
UsePAM yes
PermitRootLogin no
EOF

  # Validate config before applying
  sshd -t || die "sshd invalid"

  # Try reload first (safer than restart during remote session)
  if systemctl is-active --quiet ssh; then
    systemctl reload ssh || systemctl restart ssh
  elif systemctl is-active --quiet sshd; then
    systemctl reload sshd || systemctl restart sshd
  else
    # Fallback: try common names
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
  fi

  log "SSH config applied: PasswordAuthentication=$yn, KbdInteractiveAuthentication=$yn, PermitRootLogin=no"
}
