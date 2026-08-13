#!/usr/bin/env bash
set -euo pipefail

# update-phone.sh — legacy/compat name for update-home.sh (kept so older
# workflows and the README keep working). Same as `bash update-home.sh`.
exec bash "$(dirname "$0")/update-home.sh"