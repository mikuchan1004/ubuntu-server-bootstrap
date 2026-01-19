#!/usr/bin/env bash
set -Eeuo pipefail
run_10_init(){
  timedatectl set-timezone "$1" || true
}
