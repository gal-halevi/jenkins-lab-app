#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_venv

python3.12 -m venv "$(dirname "$VENV_DIR")"
"$VENV_BIN/pip" install -r requirements-dev.txt . --no-deps
