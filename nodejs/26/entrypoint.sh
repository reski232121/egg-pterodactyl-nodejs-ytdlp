#!/bin/bash
cd /home/container || exit 1

# Make internal Docker IP available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# yt-dlp user-install (agar bisa di-update tanpa root)
export PATH="$HOME/.local/bin:$PATH"

# Print versions
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0mnode -v\n"
node -v

# Auto-update yt-dlp saat start (set AUTO_UPDATE_YTDLP=1 di egg)
if [ "${AUTO_UPDATE_YTDLP}" = "1" ]; then
    printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0mupdating yt-dlp\n"
    pip3 install --user --upgrade --quiet --break-system-packages "yt-dlp[default]" \
        || echo "Gagal update yt-dlp, memakai versi bawaan image."
fi
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0myt-dlp --version\n"
yt-dlp --version

# Jalankan npm install hanya jika ada package.json dan belum ada node_modules
if [ -f package.json ] && [ ! -d node_modules ]; then
    printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0mnpm install\n"
    npm install --prefer-offline --no-audit
fi

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo "$(date '+%Y-%m-%d %H:%M:%S') : Starting server with command: $MODIFIED_STARTUP"

# Run the Server
eval "${MODIFIED_STARTUP}"
