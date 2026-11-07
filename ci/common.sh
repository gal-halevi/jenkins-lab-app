# ci/common.sh: sourced by every ci/*.sh script, never run directly.
# shellcheck shell=bash

# Repo root, from this file's location, so scripts work from any directory.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

VENV_DIR="${VENV_DIR:-.venv}"
VENV_BIN="$VENV_DIR/bin"

# Fail early with a useful message instead of "command not found" halfway through.
require_venv() {
    [[ -x "$VENV_BIN/python" ]] || { log "No venv at $VENV_DIR. Run ci/setup.sh first."; exit 1; }
}
