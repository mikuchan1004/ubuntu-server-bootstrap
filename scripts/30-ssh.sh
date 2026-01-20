#!/usr/bin/env bash
set -Eeuo pipefail

# Expect these helpers from scripts/00-common.sh:
# - log, die
# NOTE: install.sh에서 이미 00-common.sh를 source한 뒤 이 파일을 source하므로
# 여기서 다시 source하지 않는 방식(레포 스타일 유지)

# Normalize boolean-ish input into OpenSSH yes/no
_to_yesno() {
  local v="${1:-true}"
  case "$v" in
    true|yes|on|1)  echo "yes" ;;
    false|no|off|0) echo "no" ;;
    *) die "run_30_ssh: allow must be true|false (got: $v)" ;;
  esac
}

_detect_ssh_service() {
  # Prefer the one that exists/enabled/active
  if systemctl list-unit-files | awk '{print $1}' | grep -qx 'ssh.service'; then
    echo "ssh"
    return 0
  fi
  if systemctl list-unit-files | awk '{print $1}' | grep -qx 'sshd.service'; then
    echo "sshd"
    return 0
  fi

  # Fallback guesses
  if systemctl status ssh >/dev/null 2>&1; then
    echo "ssh"
    return 0
  fi
  if systemctl status sshd >/dev/null 2>&1; then
    echo "sshd"
    return 0
  fi

  # As last resort
  echo "ssh"
}

_reload_or_restart() {
  local svc="$1"
  # reload is safer for existing SSH sessions
  if systemctl is-active --quiet "$svc"; then
    systemctl reload "$svc" >/dev/null 2>&1 && return 0
    systemctl restart "$svc" >/dev/null 2>&1 && return 0
  else
    # If not active, try start
    systemctl start "$svc" >/dev/null 2>&1 && return 0
    systemctl restart "$svc" >/dev/null 2>&1 && return 0
  fi

  # Fallback to the other name if first failed
  if [[ "$svc" == "ssh" ]]; then
    systemctl reload sshd >/dev/null 2>&1 || systemctl restart sshd >/dev/null 2>&1 || true
  else
    systemctl reload ssh >/dev/null 2>&1 || systemctl restart ssh >/dev/null 2>&1 || true
  fi
}

run_30_ssh() {
  local allow="${1:-true}"
  local yn
  yn="$(_to_yesno "$allow")"

  local conf_dir="/etc/ssh/sshd_config.d"
  local conf_file="${conf_dir}/99-zz-bootstrap.conf"

  log "Configuring SSH (PasswordAuthentication=${yn}, KbdInteractiveAuthentication=${yn}, PermitRootLogin=no)"

  # Ensure drop-in directory exists
  install -d -m 0755 "$conf_dir"

  cat > "$conf_file" <<EOF
# Managed by ubuntu-server-bootstrap
# DO NOT EDIT manually unless you know what you're doing.
PubkeyAuthentication yes
PasswordAuthentication ${yn}
KbdInteractiveAuthentication ${yn}
UsePAM yes
PermitRootLogin no
EOF

  # Validate sshd config
  sshd -t || die "sshd invalid after writing ${conf_file}"

  # Apply safely
  local svc
  svc="$(_detect_ssh_service)"

  log "Applying SSH config via systemd (${svc}.service): reload -> restart fallback"
  _reload_or_restart "$svc"

  # Basic sanity: sshd config still valid after reload/restart
  sshd -t || die "sshd became invalid after service reload/restart"

  log "SSH configuration applied successfully."
}
