#!/bin/bash
# Reduces Codespaces auto-stop from idle (~30m default) by doing periodic lightweight activity.
# Also set GitHub → Settings → Codespaces → "Default idle timeout" to 240 minutes (org max may vary).
INTERVAL="${KEEPALIVE_INTERVAL_SECONDS:-240}"

touch_workspaces() {
  shopt -s nullglob
  for ws in /workspaces/*; do
    if [ -d "$ws" ] && [ -w "$ws" ]; then
      touch "$ws/.codespace-keepalive" 2>/dev/null || true
    fi
  done
  shopt -u nullglob
}

one_round() {
  touch_workspaces
  touch /tmp/.codespace-keepalive 2>/dev/null || true
  curl -sk --connect-timeout 2 --max-time 5 "https://127.0.0.1:443/" >/dev/null 2>&1 || true
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh api user -q .login >/dev/null 2>&1 || true
  fi
}

one_round
while true; do
  sleep "$INTERVAL" || true
  one_round
done
