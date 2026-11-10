#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

command -v shellcheck >/dev/null || {
    log "Need shellcheck, but it isn't on PATH. Install it."
    exit 1
}
find ci/ -type f -name "*.sh" -exec shellcheck {} +
