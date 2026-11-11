#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

require_venv

# Release tags must match this. Keep in sync with git_describe_command in pyproject.toml.
TAG_PATTERN='v[0-9]*'

if ! git describe --match "$TAG_PATTERN" >/dev/null 2>&1; then
    log "No release tag matching '$TAG_PATTERN' is reachable from HEAD ($(git rev-parse --short HEAD))."
    if [[ "$(git rev-parse --is-shallow-repository)" == true ]]; then
        log "This is a shallow clone, so the tagged commit isn't in the downloaded history."
        log "Jenkins: turn off shallow clone in the job's checkout. Locally: git fetch --unshallow --tags"
    else
        log "Either tags weren't fetched, or no release tag exists yet."
        log "Jenkins: make the job's checkout fetch tags. Locally: git fetch --tags"
        log "First release: git tag -a v0.1.0 -m 'Release 0.1.0' && git push origin v0.1.0"
    fi
    exit 1
fi

"$VENV_BIN/python" -m setuptools_scm
