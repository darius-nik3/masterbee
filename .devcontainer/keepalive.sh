#!/bin/bash
# Keep GitHub Codespaces from idling out, WITHOUT touching the xray
# port, xray config, or port visibility.
#
# Strategy: every few minutes do small read-only activity that GitHub
# counts as a live session:
#   * authenticated GitHub API call (uses GITHUB_TOKEN / gh auth)
#   * touch a marker file inside /workspaces (filesystem activity)
# These do NOT alter the proxy port (443), its visibility, or xray
# config in any way.
#
# Also remember to set GitHub -> Settings -> Codespaces -> "Default
# idle timeout" to 240 minutes. New value only applies to NEW
# codespaces, so recreate the codespace once after changing it.

set +e

INTERVAL="${KEEPALIVE_INTERVAL_SECONDS:-240}"
LOG_FILE="${KEEPALIVE_LOG:-/tmp/keepalive.log}"
MARKER="${KEEPALIVE_MARKER:-/tmp/.codespace-keepalive}"

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

log() {
    printf '[keepalive %s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" \
        >> "$LOG_FILE" 2>/dev/null || true
}

call_github_api() {
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    if [ -n "$token" ]; then
        curl -ks --connect-timeout 5 --max-time 10 \
             -H "Authorization: Bearer ${token}" \
             -H 'Accept: application/vnd.github+json' \
             'https://api.github.com/user' -o /dev/null 2>/dev/null || true
        log 'github api heartbeat (token)'
        return
    fi
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        gh api user -q .login >/dev/null 2>&1 || true
        log 'github api heartbeat (gh)'
    fi
}

touch_workspace() {
    shopt -s nullglob
    for ws in /workspaces/*; do
        if [ -d "$ws" ] && [ -w "$ws" ]; then
            touch "$ws/.codespace-keepalive" 2>/dev/null || true
        fi
    done
    shopt -u nullglob
    touch "$MARKER" 2>/dev/null || true
}

trap 'log "received signal, exiting"; exit 0' INT TERM

log "starting (interval=${INTERVAL}s, codespace=${CODESPACE_NAME:-unknown})"

while true; do
    touch_workspace
    call_github_api
    sleep "${INTERVAL}" 2>/dev/null || sleep 60
done
