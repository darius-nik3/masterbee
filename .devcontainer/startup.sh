#!/bin/bash
# Codespace start-up: prints connection details, launches the keep-alive
# daemon in the background, and keeps xray alive with a respawn loop.

set -u

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║          🚀 G2RAY - XRAY SERVICE INITIALIZED 🚀           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Configuration:"
echo "   • Config File: /etc/config.json"
echo ""
echo "🔗 VLESS Connection Details:"
echo "   • Link: vless://550e8400-e29b-41d4-a716-446655440000@94.130.50.12:443"
echo "   • Encryption: none"
echo "   • Security: tls"
echo "   • Type: xhttp"
echo "   • Mode: packet-up"
echo "   • SNI: ${CODESPACE_NAME:-<codespace>}-443.app.github.dev"
echo ""
echo "✨ Service is running and ready to accept connections..."
echo ""

# Start the keep-alive daemon fully detached so it survives shell exec/exit.
# pgrep guard prevents duplicates when postAttachCommand fires multiple times.
if ! pgrep -f '/app/keepalive.sh' >/dev/null 2>&1; then
    nohup /app/keepalive.sh </dev/null >/tmp/keepalive.log 2>&1 &
    disown || true
    echo "🫀 keep-alive daemon started (logs: /tmp/keepalive.log)"
else
    echo "🫀 keep-alive daemon already running"
fi

# Respawn xray if it ever exits so the codespace never goes "stopped".
while true; do
    /usr/local/bin/xray -c /etc/config.json
    code=$?
    echo "⚠️  xray exited with code ${code}, restarting in 5s..." >&2
    sleep 5
done
