#!/bin/bash
# Bullet-proof GitHub Codespaces keep-alive.
#
# GitHub Codespaces' idle timer is driven by:
#   1) Active VS Code / SSH client connections
#   2) Incoming traffic through the port-forwarding service
# Internal filesystem activity is NOT enough. The only reliable trick is to
# generate EXTERNAL traffic that re-enters the codespace through GitHub's
# port forwarder, which resets the idle timer every time.
#
# Also remember to set GitHub -> Settings -> Codespaces -> "Default idle
# timeout" to 240 minutes (the maximum). New value only applies to NEW
# codespaces, so re-create the codespace once after changing the setting.

set +e

INTERVAL="${KEEPALIVE_INTERVAL_SECONDS:-180}"   # 3 minutes, well under 30
PORT="${KEEPALIVE_PORT:-443}"
LOG_FILE="${KEEPALIVE_LOG:-/tmp/keepalive.log}"
MARKER="${KEEPALIVE_MARKER:-/tmp/.codespace-keepalive}"

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
: > "$LOG_FILE" 2>/dev/null || true

log() {
    printf '[keepalive %s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" \
        >> "$LOG_FILE" 2>/dev/null || true
}

codespace_url() {
    [ -z "${CODESPACE_NAME:-}" ] && return 0
    local domain="${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-app.github.dev}"
    printf 'https://%s-%s.%s/' "$CODESPACE_NAME" "$PORT" "$domain"
}

ensure_port_public() {
    [ -z "${CODESPACE_NAME:-}" ] && return 0
    command -v gh >/dev/null 2>&1 || return 0
    gh codespace ports visibility "${PORT}:public" \
        -c "${CODESPACE_NAME}" >/dev/null 2>&1 || true
}

ping_external_url() {
    local url; url="$(codespace_url)"
    [ -z "$url" ] && return 0
    local code
    code="$(curl -ksSL --connect-timeout 8 --max-time 15 \
                 -H 'User-Agent: ghcs-keepalive/2.0' \
                 -H 'Cache-Control: no-cache' \
                 -o /dev/null -w '%{http_code}' "$url" 2>/dev/null)"
    log "ping ${url} -> HTTP ${code:-error}"
}

call_github_api() {
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    [ -z "$token" ] && return 0
    curl -ks --connect-timeout 5 --max-time 10 \
         -H "Authorization: Bearer ${token}" \
         -H 'Accept: application/vnd.github+json' \
         'https://api.github.com/user' -o /dev/null 2>/dev/null || true
    log 'github api heartbeat'
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

log "starting (interval=${INTERVAL}s, port=${PORT}, codespace=${CODESPACE_NAME:-unknown})"

ensure_port_public

while true; do
    touch_workspace
    ping_external_url
    call_github_api
    sleep "${INTERVAL}" 2>/dev/null || sleep 60
done
