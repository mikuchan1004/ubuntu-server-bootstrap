#!/usr/bin/env bash
set -Eeuo pipefail

run_30_ssh() {
  local allow_password="$1"

  log "[30-ssh] Configure sshd (safe apply)"

  local pa="yes"
  local kbd="yes"

  if [[ "$allow_password" == "true" ]]; then
    pa="yes"
    kbd="yes"
  else
    pa="no"
    kbd="no"
  fi

  # Late-loaded drop-in file to override cloudimg defaults reliably
  local drop="/etc/ssh/sshd_config.d/99-zz-bootstrap.conf"
  backup_file "$drop"

  write_file_root "$drop" "# Managed by ubuntu-server-bootstrap
# Loads late (99-zz-*), so it overrides cloudimg defaults.

PubkeyAuthentication yes

PasswordAuthentication ${pa}
KbdInteractiveAuthentication ${kbd}
UsePAM yes

PermitRootLogin no
MaxAuthTries 4
LoginGraceTime 30
ClientAliveInterval 120
ClientAliveCountMax 2
"

  log "[30-ssh] Validate sshd config"
  sshd -t || die "sshd config test failed. Check: $drop"

  log "[30-ssh] Restart ssh"
  systemctl restart ssh

  log "[30-ssh] Effective:"
  sshd -T | egrep 'passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitrootlogin' | tee -a "$LOG_FILE" >/dev/null

  log "[30-ssh] Done"
}
