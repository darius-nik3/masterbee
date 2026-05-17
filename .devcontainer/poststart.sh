#!/bin/bash
# Runs on container start (before IDE attach): keepalive + public port 443.

set +e

if ! pgrep -f '/app/keepalive.sh' >/dev/null 2>&1; then
    nohup /app/keepalive.sh </dev/null >>/tmp/keepalive.log 2>&1 &
    disown 2>/dev/null || true
fi

if command -v gh >/dev/null 2>&1 && [ -n "${CODESPACE_NAME:-}" ]; then
    gh codespace ports visibility 443:public -c "$CODESPACE_NAME" >/dev/null 2>&1 || true
fi
