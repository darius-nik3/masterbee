FROM debian:bookworm-slim

COPY install.sh /app/install.sh

WORKDIR /app

# Install dependencies with clear output
RUN echo "📦 Installing system dependencies..." && \
    apt-get update && apt-get install -y --no-install-recommends \
    bash git curl wget unzip tzdata openssl ca-certificates procps \
    && echo "✅ Dependencies installed successfully" \
    && rm -rf /var/lib/apt/lists/*

# Setup and configure xray
RUN echo "⚙️  Running installation script..." && \
    chmod +x /app/install.sh && /app/install.sh && \
    echo "✅ Installation completed successfully"

COPY config.json /etc/config.json
COPY keepalive.sh /app/keepalive.sh
COPY startup.sh   /app/startup.sh

RUN chmod +x /app/keepalive.sh /app/startup.sh

CMD ["/app/startup.sh"]
