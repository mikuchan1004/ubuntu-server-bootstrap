#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------
# Common helpers (must provide: log, die, require_root, ensure_ubuntu)
# ------------------------------------------------------------
source "$SCRIPT_DIR/scripts/00-common.sh"

# ------------------------------------------------------------
# Defaults
# ------------------------------------------------------------
ADMIN_USER="admin"
ADMIN_SHELL="/bin/bash"
ADMIN_PUBKEY=""
ADMIN_PUBKEY_FILE=""
ALLOW_PASSWORD_SSH="true"     # true|false (we keep this; ssh step will normalize to yes/no)
SET_ADMIN_PASSWORD=""         # optional
TIMEZONE="Asia/Seoul"
PROFILE="dev"                 # dev|prod
DISABLE_CLOUD_INIT="false"

SWAP_MB="2048"
JOURNAL_MAX_USE="200M"
JOURNAL_MAX_FILE="50M"

DRY_RUN="false"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
usage() {
cat <<'EOF'
Usage:
  sudo bash install.sh [options]

Options:
  --profile dev|prod                 (default: dev)
  --admin-user <name>                (default: admin)
  --admin-shell <path>               (default: /bin/bash)
  --admin-pubkey "<ssh pubkey>"      install authorized_keys
  --admin-pubkey-file <path>         read pubkey from file (recommended)
  --set-admin-password "<password>"  set admin password (optional)

  --allow-password-ssh true|false    (default: true; forced false on prod)
  --disable-cloud-init               create /etc/cloud/cloud-init.disabled
  --timezone <TZ>                    (default: Asia/Seoul)

  --swap-mb <mb>                     (default: 2048)
  --journal-max-use <size>           (default: 200M)
  --journal-max-file <size>          (default: 50M)

  --dry-run                          print actions only (requires scripts to respect DRY_RUN env)
  -h, --help

Examples:
  sudo bash install.sh --profile dev --admin-user admin --admin-pubkey-file keys/admin.pub --allow-password-ssh true
  sudo bash install.sh --profile prod --admin-user admin --admin-pubkey "$(cat keys/admin.pub)"
EOF
}

is_bool() { [[ "${1:-}" == "true" || "${1:-}" == "false" ]]; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# Very light sanity check: one-line ssh key starting with typical prefixes
looks_like_pubkey() {
  local k="${1:-}"
  [[ "$k" =~ ^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|sk-ssh-ed25519@openssh\.com)[[:space:]]+[^[:space:]]+([[:space:]].*)?$ ]]
}

# For safer SSH changes, ensure we are running under SSH or local console.
# Not a blocker, just a warning.
warn_if_remote_ssh() {
  if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" ]]; then
    log "NOTE: Running over SSH. SSH config changes will be applied carefully (validate + reload)."
  fi
}

# ------------------------------------------------------------
# Parse args
# ------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2;;
    --admin-user) ADMIN_USER="${2:-}"; shift 2;;
    --admin-shell) ADMIN_SHELL="${2:-}"; shift 2;;
    --admin-pubkey) ADMIN_PUBKEY="${2:-}"; shift 2;;
    --admin-pubkey-file) ADMIN_PUBKEY_FILE="${2:-}"; shift 2;;
    --set-admin-password) SET_ADMIN_PASSWORD="${2:-}"; shift 2;;

    --allow-password-ssh) ALLOW_PASSWORD_SSH="${2:-}"; shift 2;;
    --disable-cloud-init) DISABLE_CLOUD_INIT="true"; shift 1;;
    --timezone) TIMEZONE="${2:-}"; shift 2;;

    --swap-mb) SWAP_MB="${2:-}"; shift 2;;
    --journal-max-use) JOURNAL_MAX_USE="${2:-}"; shift 2;;
    --journal-max-file) JOURNAL_MAX_FILE="${2:-}"; shift 2;;

    --dry-run) DRY_RUN="true"; shift 1;;
    -h|--help) usage; exit 0;;
    *) die "Unknown option: $1";;
  esac
done

# ------------------------------------------------------------
# Pre-flight validation
# ------------------------------------------------------------
require_root
ensure_ubuntu

case "$PROFILE" in
  dev|prod) ;;
  *) die "--profile must be dev|prod (got: $PROFILE)";;
esac

is_bool "$ALLOW_PASSWORD_SSH" || die "--allow-password-ssh must be true|false (got: $ALLOW_PASSWORD_SSH)"
is_bool "$DISABLE_CLOUD_INIT" || die "internal: DISABLE_CLOUD_INIT invalid"
is_bool "$DRY_RUN" || die "internal: DRY_RUN invalid"

[[ -n "$ADMIN_USER" ]] || die "--admin-user is empty"
[[ "$ADMIN_USER" =~ ^[a-z_][a-z0-9_-]*$ ]] || die "--admin-user invalid: $ADMIN_USER"
[[ -n "$ADMIN_SHELL" ]] || die "--admin-shell is empty"

# normalize pubkey from file if provided
if [[ -n "$ADMIN_PUBKEY_FILE" ]]; then
  [[ -f "$ADMIN_PUBKEY_FILE" ]] || die "--admin-pubkey-file not found: $ADMIN_PUBKEY_FILE"
  ADMIN_PUBKEY="$(tr -d '\r' < "$ADMIN_PUBKEY_FILE" | sed -e 's/[[:space:]]*$//')"
fi

# prod policy: force disable password SSH
if [[ "$PROFILE" == "prod" ]]; then
  ALLOW_PASSWORD_SSH="false"
fi

# lockout prevention:
# - If password SSH will be disabled, we REQUIRE a pubkey.
if [[ "$ALLOW_PASSWORD_SSH" == "false" && -z "$ADMIN_PUBKEY" ]]; then
  die "Lockout prevention: password SSH is disabled, but no admin pubkey provided. Use --admin-pubkey or --admin-pubkey-file."
fi

# If pubkey is provided, do a quick sanity check (not perfect, but catches empty/garbage)
if [[ -n "$ADMIN_PUBKEY" ]] && ! looks_like_pubkey "$ADMIN_PUBKEY"; then
  die "admin pubkey does not look valid. Provide a single-line OpenSSH public key."
fi

# numeric-ish checks
[[ "$SWAP_MB" =~ ^[0-9]+$ ]] || die "--swap-mb must be an integer (got: $SWAP_MB)"

warn_if_remote_ssh
require_cmd sshd
require_cmd systemctl

# Export so scripts can read consistent inputs if they want
export BOOTSTRAP_ROOT="$SCRIPT_DIR"
export PROFILE ADMIN_USER ADMIN_SHELL ADMIN_PUBKEY ALLOW_PASSWORD_SSH SET_ADMIN_PASSWORD TIMEZONE
export SWAP_MB JOURNAL_MAX_USE JOURNAL_MAX_FILE DISABLE_CLOUD_INIT DRY_RUN

# ------------------------------------------------------------
# Load step scripts (fail fast if missing)
# ------------------------------------------------------------
for f in \
  "$SCRIPT_DIR/scripts/05-precheck.sh" \
  "$SCRIPT_DIR/scripts/10-init.sh" \
  "$SCRIPT_DIR/scripts/20-admin-user.sh" \
  "$SCRIPT_DIR/scripts/30-ssh.sh" \
  "$SCRIPT_DIR/scripts/40-motd-banner.sh"
do
  [[ -f "$f" ]] || die "Missing script: $f"
  # shellcheck disable=SC1090
  source "$f"
done

# Verify expected functions exist
for fn in run_05_precheck run_10_init run_20_admin_user run_30_ssh run_40_motd_banner; do
  declare -F "$fn" >/dev/null 2>&1 || die "Missing function: $fn (check scripts/*)"
done

# ------------------------------------------------------------
# Start
# ------------------------------------------------------------
log "=== Bootstrap start (profile=$PROFILE) ==="
log "Admin user         : $ADMIN_USER"
log "Admin shell        : $ADMIN_SHELL"
log "Allow pw SSH       : $ALLOW_PASSWORD_SSH (prod forces false)"
log "Timezone           : $TIMEZONE"
log "Swap (MB)          : $SWAP_MB"
log "Journald max       : $JOURNAL_MAX_USE / $JOURNAL_MAX_FILE"
log "Disable cloud-init : $DISABLE_CLOUD_INIT"
log "Dry run            : $DRY_RUN"

# Step 05: precheck
run_05_precheck

# Optional: disable cloud-init early (reduces interference on first boot)
if [[ "$DISABLE_CLOUD_INIT" == "true" ]]; then
  log "Disabling cloud-init (touch /etc/cloud/cloud-init.disabled)"
  if [[ "$DRY_RUN" == "true" ]]; then
    log "[dry-run] would: mkdir -p /etc/cloud && touch /etc/cloud/cloud-init.disabled"
  else
    mkdir -p /etc/cloud
    touch /etc/cloud/cloud-init.disabled
  fi
fi

# Step 10: init
run_10_init "$TIMEZONE" "$SWAP_MB" "$JOURNAL_MAX_USE" "$JOURNAL_MAX_FILE"

# Step 20: admin user
run_20_admin_user "$ADMIN_USER" "$ADMIN_SHELL" "$ADMIN_PUBKEY" "$SET_ADMIN_PASSWORD"

# Step 30: ssh hardening (script should: write drop-in, sshd -t, reload/restart safely)
run_30_ssh "$ALLOW_PASSWORD_SSH"

# Step 40: motd banner
run_40_motd_banner

log "=== Bootstrap done ==="
if [[ "$PROFILE" == "prod" ]]; then
  log "NOTE: prod profile enforced password SSH disabled."
fi
