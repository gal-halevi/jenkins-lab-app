#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

python3.12 -m venv "$VENV_DIR"
"$VENV_BIN/pip" install -r requirements-dev.txt . --no-deps
