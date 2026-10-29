ARG NODE_VERSION=25

FROM --platform=$TARGETOS/$TARGETARCH node:${NODE_VERSION}-bookworm-slim

LABEL author="Ryuzetsu" maintainer="ryuzetsu342@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/reski232121/egg-pterodactyl-nodejs-ytdlp"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=${NODE_VERSION}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        git \
        tar \
        gzip \
        unzip \
        zip \
        sqlite3 \
        libsqlite3-dev \
        python3 \
        python3-pip \
        python3-dev \
        ffmpeg \
        iproute2 \
        dnsutils \
        tzdata \
        build-essential \
        libssl-dev \
        libffi-dev \
        pkg-config \
        tini \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages yt-dlp

RUN npm install --global typescript ts-node @types/node tsx

RUN useradd -m -d /home/container container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
