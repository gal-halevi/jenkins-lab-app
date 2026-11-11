#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Host interpreter used to create the venv: version from .python-version, overridable.
PYTHON="${PYTHON:-python$(<.python-version)}"
command -v "$PYTHON" >/dev/null || {
    log "Need Python $(<.python-version), but '$PYTHON' isn't on PATH. Install it, or set PYTHON=/path/to/python."
    exit 1
}

log "Creating $VENV_DIR with $("$PYTHON" --version)"
"$PYTHON" -m venv --clear "$VENV_DIR"
"$VENV_BIN/pip" install -r requirements-dev.txt --no-deps
"$VENV_BIN/pip" install . --no-deps --no-build-isolation
"$VENV_BIN/pip" check
