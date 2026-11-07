#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_venv

PYTEST_REPORT="${PYTEST_REPORT:-reports/pytest-report.xml}"

"$VENV_BIN/pytest" -m "not slow" --junitxml="$PYTEST_REPORT" tests/
