#!/usr/bin/env bash
# Security checks. Exit codes: 0 = clean, 3 = warnings only, anything else = failure.
# Policy: vulnerable runtime deps fail; vulnerable dev/build deps warn;
#         bandit HIGH fails, MEDIUM warns, LOW and low-confidence findings are ignored.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

readonly WARNINGS_EXIT=3
REPORT_DIR="${REPORT_DIR:-reports}"
BANDIT_SRC="${BANDIT_SRC:-src}"
BANDIT_CONFIDENCE="${BANDIT_CONFIDENCE:-medium}"

command -v jq >/dev/null || { log "Need jq, but it isn't on PATH. Install it."; exit 1; }
require_venv
mkdir -p "$REPORT_DIR"
warnings=0

# Audit one lock file. Prints the number of distinct vulnerabilities (stdout);
# lists them on stderr. Returns non-zero if pip-audit failed without a usable report.
audit_lock() {
    local lock="$1" report="$2" rc=0 count
    rm -f "$report"
    "$VENV_BIN/pip-audit" -r "$lock" --no-deps --disable-pip --progress-spinner off \
        -f json -o "$report" || rc=$?
    count=$(jq '[.dependencies[].vulns[].id] | unique | length' "$report") || {
        log "pip-audit on $lock failed (exit $rc) without a valid report"
        return 1
    }
    if (( rc != 0 && count == 0 )); then
        log "pip-audit on $lock failed (exit $rc) but reported no vulnerabilities"
        return 1
    fi
    if (( count > 0 )); then
        log "$count vulnerabilities in $lock:"
        jq -r '.dependencies[] | .name as $n | .version as $v | .vulns[]
               | "    \($n) \($v): \(.id) (fix: \(.fix_versions | join(", ")))"' "$report" \
            | sort -u >&2
    fi
    printf '%s\n' "$count"
}

log "pip-audit: runtime dependencies (blocking)"
runtime=$(audit_lock requirements.txt "$REPORT_DIR/pip-audit-runtime.json")
if (( runtime > 0 )); then
    log "FAIL: vulnerable runtime dependencies"
    exit 1
fi

log "pip-audit: dev and build dependencies (warning)"
dev=$(audit_lock requirements-dev.txt "$REPORT_DIR/pip-audit-dev.json")
if (( dev > 0 )); then warnings=$((warnings + 1)); fi

log "bandit: $BANDIT_SRC (HIGH fails, MEDIUM warns)"
[[ -d "$BANDIT_SRC" ]] || { log "FAIL: '$BANDIT_SRC' doesn't exist (bandit would call that clean)"; exit 1; }
bandit_report="$REPORT_DIR/bandit.json"
rm -f "$bandit_report"
rc=0
"$VENV_BIN/bandit" -q -r "$BANDIT_SRC" --severity-level medium \
    --confidence-level "$BANDIT_CONFIDENCE" -f json -o "$bandit_report" || rc=$?
if (( rc > 1 )); then
    log "FAIL: bandit failed (exit $rc)"
    exit 1
fi
jq -r '.results[] | "    \(.test_id) \(.issue_severity)/\(.issue_confidence) \(.filename):\(.line_number) \(.issue_text)"' \
    "$bandit_report" >&2
errors=$(jq '.errors | length' "$bandit_report")
high=$(jq '[.results[] | select(.issue_severity == "HIGH")] | length' "$bandit_report")
medium=$(jq '[.results[] | select(.issue_severity == "MEDIUM")] | length' "$bandit_report")
if (( errors > 0 )); then
    log "FAIL: bandit couldn't scan $errors file(s)"
    exit 1
fi
if (( high > 0 )); then
    log "FAIL: $high high-severity finding(s)"
    exit 1
fi
if (( medium > 0 )); then warnings=$((warnings + 1)); fi

if (( warnings > 0 )); then
    log "Security: warnings only ($warnings check(s) with findings)"
    exit "$WARNINGS_EXIT"
fi
log "Security: clean"
