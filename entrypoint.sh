#!/bin/bash

TZ=${TZ:-UTC}
export TZ

INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

cd /home/container || exit 1

echo "Node.js Version: $(node -v)"
echo "npm Version: $(npm -v)"
echo "FFmpeg Version: $(ffmpeg -version | head -n 1)"
echo "yt-dlp Version: $(yt-dlp --version)"
echo "Python3 Version: $(python3 --version)"
echo ""

PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

echo "Starting server with command:"
echo "$PARSED"
echo ""

exec env ${PARSED}
