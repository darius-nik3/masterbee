FROM debian:bookworm-slim

LABEL maintainer="@Kakoolnews" \
      description="VLESS proxy via GitHub Codespaces"

COPY install.sh /app/install.sh

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash git curl wget unzip tzdata openssl ca-certificates uuid-runtime procps \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /app/install.sh && /app/install.sh

COPY config.json /etc/config.template.json
COPY keepalive.sh startup.sh poststart.sh /app/
RUN chmod +x /app/keepalive.sh /app/startup.sh /app/poststart.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:443/ || exit 1

CMD ["/app/startup.sh"]
