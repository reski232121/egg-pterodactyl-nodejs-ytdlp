ARG NODE_VERSION=20

FROM --platform=$TARGETOS/$TARGETARCH node:${NODE_VERSION}-bullseye-slim

LABEL author="Ryuzetsu" maintainer="reski232121@gmail.com"
LABEL org.opencontainers.image.source="https://github.com/reski232121/egg-pterodactyl-nodejs-ytdlp"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive

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
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir yt-dlp

RUN npm install --global npm@latest typescript ts-node @types/node tsx

RUN useradd -m -d /home/container container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
