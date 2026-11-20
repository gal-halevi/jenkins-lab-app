#!/usr/bin/env bash

set -euo pipefail
VENV_DIR=".venv-verify"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

: "${APP_VERSION:?APP_VERSION is not set. Jenkins sets it in the Version stage; locally: APP_VERSION=\$(ci/version.sh) ci/verify.sh}"
log "Verifying labapp $APP_VERSION"

wheel=$(find_wheel)
log "Verifying wheel $wheel"
(
    cd dist
    sha256sum -c "$wheel.sha256"
)

make_venv requirements.txt "dist/$wheel"

installed_version="$("$VENV_BIN/python" -c "from importlib.metadata import version; print(version('labapp'))")"
if [[ "$installed_version" != "$APP_VERSION" ]]; then
    log "Installed version $installed_version does not match expected version $APP_VERSION"
    exit 1
fi

log "Smoke test: GET /health from the installed wheel"
# inline on purpose: CI Python isn’t linted yet, see the plan
"$VENV_BIN/python" - <<'PY'
import os
from labapp import create_app

expected = os.environ["APP_VERSION"]
resp = create_app().test_client().get("/health")
body = resp.get_json() or {}
if resp.status_code != 200 or body.get("version") != expected:
    raise SystemExit(
        f"Smoke test failed: status {resp.status_code}, body {body}, expected version {expected}"
    )
print(f"/health OK: {body}")
PY
