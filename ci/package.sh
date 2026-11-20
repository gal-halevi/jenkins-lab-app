#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_venv

rm -rf dist
"$VENV_BIN/python" -m build --no-isolation --wheel

(
    cd dist
    shopt -s nullglob
    wheels=(*.whl)
    if (( ${#wheels[@]} != 1 )); then
        log "Expected exactly one wheel in dist/, found ${#wheels[@]}: ${wheels[*]:-none}"
        exit 1
    fi
    sha256sum "${wheels[0]}" > "${wheels[0]}.sha256"
)
