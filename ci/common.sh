# ci/common.sh: sourced by every ci/*.sh script, never run directly.
# shellcheck shell=bash

# Repo root, from this file's location, so scripts work from any directory.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

VENV_DIR="${VENV_DIR:-.venv}"
VENV_BIN="$VENV_DIR/bin"

log() { printf '==> %s\n' "$*" >&2; }

# Fail early with a useful message instead of "command not found" halfway through.
require_venv() {
    [[ -x "$VENV_BIN/python" ]] || { log "No venv at $VENV_DIR. Run ci/setup.sh first."; exit 1; }
}

find_python() {
    # Host interpreter used to create the venv: version from .python-version, overridable.
    local python="${PYTHON:-python$(<.python-version)}"
    command -v "$python" >/dev/null || {
        log "Need Python $(<.python-version), but '$python' isn't on PATH. Install it, or set PYTHON=/path/to/python."
        return 1
    }
    printf '%s\n' "$python"
}

find_wheel() (
    cd dist || { log "No dist/ directory. Run ci/package.sh first."; return 1; }
    shopt -s nullglob
    wheels=(*.whl)
    if (( ${#wheels[@]} != 1 )); then
        log "Expected exactly one wheel in dist/, found ${#wheels[@]}: ${wheels[*]:-none}"
        return 1
    fi
    printf '%s\n' "${wheels[0]}"
)

make_venv() {
    local lock_file="${1:?make_venv: lock file required}"
    local install_target="${2:?make_venv: install target required}"
    local python
    python=$(find_python)
    log "Creating $VENV_DIR with $("$python" --version)"
    "$python" -m venv --clear "$VENV_DIR"
    "$VENV_BIN/pip" install -r "$lock_file" --no-deps
    # --no-build-isolation when installing "." which builds the package; does nothing for a wheel
    "$VENV_BIN/pip" install "$install_target" --no-deps --no-build-isolation
    "$VENV_BIN/pip" check
}
