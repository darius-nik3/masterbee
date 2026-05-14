#!/bin/bash
# Codespace start-up: prints connection details, launches the keep-alive
# daemon in the background, then exec's xray exactly like the original
# inline startup did. The xray launch line is intentionally identical to
# the original Dockerfile-generated startup.sh so connection behaviour
# does NOT change.

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
echo "   • SNI: ${CODESPACE_NAME}-443.app.github.dev"
echo ""
echo "✨ Service is running and ready to accept connections..."
echo ""

# Keep-alive daemon, fully detached, never touches xray or its config.
if ! pgrep -f '/app/keepalive.sh' >/dev/null 2>&1; then
    nohup /app/keepalive.sh </dev/null >/tmp/keepalive.log 2>&1 &
    disown || true
fi

exec /usr/local/bin/xray -c /etc/config.json
