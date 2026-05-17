#!/bin/bash
# Start xray with a stable UUID and WebSocket config. Safe to run again after
# codespace stop/start or re-attach (kills stale xray, reuses saved UUID).

set -eu

CONFIG_TEMPLATE="/etc/config.template.json"
CONFIG="/etc/config.json"
UUID_FILE=""

generate_uuid() {
    prefix="4b616b6f-6f6c-4e65-7773"
    suffix=$(od -An -tx1 -N6 /dev/urandom | tr -d ' \n')
    echo "${prefix}-${suffix}"
}

find_uuid_file() {
    if [ -n "${VLESS_UUID_FILE:-}" ] && [ -w "$(dirname "$VLESS_UUID_FILE")" ]; then
        echo "$VLESS_UUID_FILE"
        return
    fi
    for ws in /workspaces/*/; do
        [ -d "$ws" ] || continue
        if [ -w "$ws" ]; then
            echo "${ws}.mozi-vless-uuid"
            return
        fi
    done
    echo "/tmp/.mozi-vless-uuid"
}

load_or_create_uuid() {
    if [ -n "${VLESS_UUID:-}" ]; then
        echo "$VLESS_UUID"
        return
    fi
    UUID_FILE="$(find_uuid_file)"
    if [ -f "$UUID_FILE" ]; then
        tr -d ' \n\r' < "$UUID_FILE"
        return
    fi
    uuid="$(generate_uuid)"
    mkdir -p "$(dirname "$UUID_FILE")" 2>/dev/null || true
    printf '%s\n' "$uuid" > "$UUID_FILE" 2>/dev/null || true
    echo "$uuid"
}

ensure_port_public() {
    if command -v gh >/dev/null 2>&1 && [ -n "${CODESPACE_NAME:-}" ]; then
        gh codespace ports visibility 443:public -c "$CODESPACE_NAME" >/dev/null 2>&1 || true
    fi
}

stop_stale_xray() {
    if command -v pkill >/dev/null 2>&1; then
        pkill -f '/usr/local/bin/xray -c /etc/config.json' 2>/dev/null || true
        sleep 1
    fi
}

start_keepalive() {
    if ! pgrep -f '/app/keepalive.sh' >/dev/null 2>&1; then
        nohup /app/keepalive.sh </dev/null >>/tmp/keepalive.log 2>&1 &
        disown 2>/dev/null || true
    fi
}

UUID="$(load_or_create_uuid)"
sed "s/\${UUID}/$UUID/g" "$CONFIG_TEMPLATE" > "$CONFIG"

SNI="${CODESPACE_NAME:-localhost}-443.app.github.dev"

echo ""
echo "========================================"
echo "  @Kakoolnews - VLESS Proxy"
echo "========================================"
echo ""
echo "VLESS links (try each IP, use whichever works best):"
echo ""
echo "vless://${UUID}@94.130.50.12:443?encryption=none&security=tls&type=ws&sni=${SNI}&path=%2F#خخ"
echo ""
echo "vless://${UUID}@63.141.252.203:443?encryption=none&security=tls&type=ws&sni=${SNI}&path=%2F#خخ"
echo ""
echo "vless://${UUID}@50.7.5.83:443?encryption=none&security=tls&type=ws&sni=${SNI}&path=%2F#خخ"
echo ""
if [ -n "${UUID_FILE:-}" ] && [ -f "$UUID_FILE" ]; then
    echo "UUID saved at: $UUID_FILE (reused on restart — same client config)"
else
    echo "UUID: $UUID"
fi
echo "========================================"
echo ""

ensure_port_public
start_keepalive
stop_stale_xray

exec /usr/local/bin/xray -c "$CONFIG"
