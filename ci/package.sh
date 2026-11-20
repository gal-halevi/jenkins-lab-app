#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_venv

rm -rf dist
"$VENV_BIN/python" -m build --no-isolation --wheel

wheel=$(find_wheel)
(
    cd dist
    sha256sum "$wheel" > "$wheel.sha256"
)
