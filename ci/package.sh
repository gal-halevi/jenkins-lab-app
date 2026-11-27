#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_venv

# Package only committed code. Modified tracked files or untracked (non-ignored) files would end up in the
# wheel; a modified file would also change the version (.d<date>).
if [[ "${ALLOW_DIRTY:-0}" != 1 ]]; then
    changed=$(git status --porcelain)
    if [[ -n "$changed" ]]; then
        log "Refusing to package: the working tree differs from commit $(git rev-parse --short HEAD):"
        printf '%s\n' "$changed" | sed 's/^/    /' >&2
        log "Package only committed code. For a local experiment: ALLOW_DIRTY=1 ci/package.sh"
        exit 1
    fi
fi

rm -rf dist
"$VENV_BIN/python" -m build --no-isolation --wheel

wheel=$(find_wheel)
(
    cd dist
    sha256sum "$wheel" > "$wheel.sha256"
)
