#!/usr/bin/env bash
set -Eeuo pipefail
run_40_motd_banner(){
  echo "Authorized access only." > /etc/issue.net
}
