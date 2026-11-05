ARG NODE_VERSION=24

FROM --platform=$TARGETOS/$TARGETARCH node:${NODE_VERSION}-bookworm-slim

LABEL author="Ryuzetsu" maintainer="ryuzetsu342@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/reski232121/egg-pterodactyl-nodejs-ytdlp"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive

# Termasuk build tools (gcc, make, python3-dev, dll.) untuk kompilasi native module
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates curl wget git tar gzip unzip zip \
        sqlite3 libsqlite3-dev python3 python3-pip python3-dev ffmpeg \
        build-essential libssl-dev libffi-dev pkg-config \
        iproute2 dnsutils tzdata tini; \
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
