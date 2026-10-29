#!/bin/bash
cd /home/container

# Make internal Docker IP available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Print Node.js version
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0mnode -v\n"
node -v

# Check if node_modules exist, if not run npm install
if [ ! -d "node_modules" ]; then
    printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0mnpm install\n"
    npm install --prefer-offline --no-audit
fi

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo "$(date '+%Y-%m-%d %H:%M:%S') : Starting server with command: $MODIFIED_STARTUP"

# Run the Server
eval ${MODIFIED_STARTUP}
