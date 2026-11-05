#!/bin/bash
# Entrypoint Pterodactyl: menyiapkan environment, lalu menyerahkan proses ke tini.
# Logika aplikasi (git pull, install deps, mode jalan) ada di /usr/local/bin/start-app.
cd /home/container || exit 1

log() { printf '\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n' "$*"; }

# IP internal Docker untuk aplikasi
INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}')
export INTERNAL_IP

export TZ="${TZ:-UTC}"
# ~/.local/bin lebih dulu, agar yt-dlp hasil update (user-install) menimpa versi bawaan image
export PATH="$HOME/.local/bin:$PATH"

log "node $(node -v) | python $(python3 -c 'import platform;print(platform.python_version())')"

# ---------- yt-dlp ----------
if [ "${AUTO_UPDATE_YTDLP:-0}" = "1" ]; then
    pip_args=()
    [ "${YTDLP_CHANNEL:-stable}" = "nightly" ] && pip_args+=(--pre)
    log "update yt-dlp (channel: ${YTDLP_CHANNEL:-stable})"
    pip3 install --user --upgrade --quiet --break-system-packages "${pip_args[@]}" \
        "yt-dlp[default,curl-cffi]" || log "update yt-dlp gagal, memakai versi yang ada"
fi

# Config yt-dlp dikelola otomatis selama baris pertamanya tidak dihapus.
# Hapus baris "# managed-by-egg" jika ingin mengatur config sendiri.
YT_CONF_DIR="$HOME/.config/yt-dlp"
YT_CONF="$YT_CONF_DIR/config"
mkdir -p "$YT_CONF_DIR" "$HOME/.cache/yt-dlp"
if [ ! -f "$YT_CONF" ] || head -n1 "$YT_CONF" | grep -q '^# managed-by-egg'; then
    {
        echo "# managed-by-egg: dibuat ulang setiap start. Hapus baris ini untuk mengatur sendiri."
        echo "--cache-dir \"$HOME/.cache/yt-dlp\""
        if [ -n "${YTDLP_COOKIES:-}" ]; then
            cookies="$YTDLP_COOKIES"
            [[ "$cookies" = /* ]] || cookies="/home/container/$cookies"
            if [ -f "$cookies" ]; then
                echo "--cookies \"$cookies\""
            else
                log "peringatan: file cookies '$cookies' tidak ditemukan, dilewati" >&2
            fi
        fi
    } > "$YT_CONF"
fi
log "yt-dlp $(yt-dlp --version 2>/dev/null || echo 'tidak ditemukan')"

# ---------- Cloudflare Tunnel ----------
# Aktif jika CLOUDFLARE_TUNNEL_TOKEN diisi. Hostname/port publik diatur di dashboard Cloudflare Zero Trust.
start_cloudflared() {
    local token="$1" proto="$2" fails=0 started rc
    while :; do
        started=$(date +%s)
        # Token dikirim lewat env TUNNEL_TOKEN (bukan argumen) agar tidak terlihat di daftar proses/log
        TUNNEL_TOKEN="$token" cloudflared tunnel --no-autoupdate --protocol "$proto" run 2>&1 \
            | sed -u 's/^/[cloudflared] /'
        rc=${PIPESTATUS[0]}
        # Berhenti jika gagal cepat berulang kali (mis. token salah), agar log tidak dibanjiri
        if [ $(( $(date +%s) - started )) -lt 20 ]; then fails=$((fails + 1)); else fails=0; fi
        if [ "$fails" -ge 5 ]; then
            log "cloudflared gagal 5x berturut-turut (kode $rc), tunnel dihentikan. Periksa CLOUDFLARE_TUNNEL_TOKEN." >&2
            return
        fi
        log "cloudflared berhenti (kode $rc), dijalankan ulang dalam 10 detik"
        sleep 10
    done
}

if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
    # Toleran jika yang ditempel adalah perintah lengkap, mis. "cloudflared service install eyJ..."
    cf_token="${CLOUDFLARE_TUNNEL_TOKEN//$'\r'/}"
    cf_token="${cf_token//$'\n'/ }"
    cf_token="${cf_token% }"
    cf_token="${cf_token##* }"
    case "$cf_token" in
        eyJ*) ;;
        *) log "peringatan: CLOUDFLARE_TUNNEL_TOKEN tidak terlihat seperti token tunnel (biasanya diawali 'eyJ')" >&2 ;;
    esac
    log "cloudflared $(cloudflared --version 2>/dev/null | awk '{print $3}') | memulai tunnel (protocol: ${CLOUDFLARE_TUNNEL_PROTOCOL:-auto})"
    start_cloudflared "$cf_token" "${CLOUDFLARE_TUNNEL_PROTOCOL:-auto}" &
    # Token tidak perlu diteruskan ke aplikasi Node.js
    unset CLOUDFLARE_TUNNEL_TOKEN cf_token
fi

# ---------- Jalankan STARTUP ----------
STARTUP="${STARTUP:-start-app}"
MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo "$(date '+%Y-%m-%d %H:%M:%S') : Starting server with command: ${MODIFIED_STARTUP}"

# exec + tini: signal Stop/Restart dari panel diteruskan ke aplikasi, zombie process dibersihkan
exec tini -g -- bash -c "${MODIFIED_STARTUP}"
