#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <venv_bin_dir>"
    exit 1
fi

VENV_BIN_DIR="$1"
python3.12 -m venv "$(dirname "$VENV_BIN_DIR")"
"$VENV_BIN_DIR/pip" install -r requirements-dev.txt . --no-deps
