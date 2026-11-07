#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_venv

"$VENV_BIN/ruff" check . && "$VENV_BIN/ruff" format --check .
