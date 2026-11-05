ARG NODE_VERSION=24

FROM --platform=$TARGETOS/$TARGETARCH node:${NODE_VERSION}-bookworm-slim

# VARIANT=full : + build tools (gcc, make, python3-dev, dll.) untuk kompilasi native module
# VARIANT=slim : tanpa build tools, image lebih kecil
ARG VARIANT=full

LABEL author="Ryuzetsu" maintainer="ryuzetsu342@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/reski232121/egg-pterodactyl-nodejs-ytdlp"
LABEL org.opencontainers.image.licenses=MIT
LABEL org.opencontainers.image.variant="${VARIANT}"

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl wget git tar gzip unzip zip \
        sqlite3 python3 python3-pip ffmpeg \
        iproute2 dnsutils tzdata tini; \
    if [ "${VARIANT}" = "full" ]; then \
        apt-get install -y --no-install-recommends \
            build-essential python3-dev libsqlite3-dev libssl-dev libffi-dev pkg-config; \
    fi; \
    rm -rf /var/lib/apt/lists/*

# yt-dlp[default]   : membawa yt-dlp-ejs (dibutuhkan YouTube); Node.js dipakai sebagai JS runtime
# yt-dlp[curl-cffi] : mendukung --impersonate (mis. --impersonate chrome)
RUN pip3 install --no-cache-dir --break-system-packages "yt-dlp[default,curl-cffi]" \
    && printf -- '--js-runtimes node\n' > /etc/yt-dlp.conf

# Cloudflare Tunnel (cloudflared): binary statis resmi dari GitHub release, sesuai arsitektur build.
# Dijalankan otomatis oleh entrypoint jika CLOUDFLARE_TUNNEL_TOKEN diisi.
ARG TARGETARCH
RUN curl -fsSL -o /usr/local/bin/cloudflared \
        "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${TARGETARCH}" \
    && chmod 755 /usr/local/bin/cloudflared \
    && cloudflared --version

# Package manager + TypeScript runner. Yarn sudah ada di image resmi Node (dipasang hanya jika belum ada).
RUN npm install --global --no-fund --no-audit pnpm bun tsx typescript \
    && (command -v yarn >/dev/null || npm install --global --no-fund --no-audit yarn) \
    && npm cache clean --force

COPY entrypoint.sh /entrypoint.sh
COPY start-app.sh /usr/local/bin/start-app
RUN chmod 755 /entrypoint.sh /usr/local/bin/start-app \
    && useradd -m -d /home/container container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

CMD ["/entrypoint.sh"]
