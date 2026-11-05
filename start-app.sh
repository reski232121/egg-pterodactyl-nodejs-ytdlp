#!/bin/bash
# start-app: git pull -> paket tambahan -> install dependencies -> jalankan aplikasi Node.js.
# Dipanggil lewat STARTUP egg. Semua opsi dibaca dari environment variable egg.
APP_DIR="${APP_DIR:-/home/container}"
cd "$APP_DIR" || exit 1

log() { printf '\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n' "$*"; }
die() { printf '\033[1m\033[31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

export NODE_ENV="${NODE_ENV:-production}"
PM="${PACKAGE_MANAGER:-npm}"
RUN_MODE="${RUN_MODE:-auto}"
TS_RUNNER="${TS_RUNNER:-tsx}"
MAIN="${MAIN_FILE:-}"

read -r NODE_MAJOR NODE_MINOR < <(node -p 'process.versions.node.split(".").slice(0,2).join(" ")')
node_gte() { [ "$NODE_MAJOR" -gt "$1" ] || { [ "$NODE_MAJOR" -eq "$1" ] && [ "$NODE_MINOR" -ge "$2" ]; }; }
# TypeScript bawaan Node tanpa flag: 22.18+, 23.6+, 24+
ts_native() { node_gte 24 0 || { [ "$NODE_MAJOR" -eq 23 ] && [ "$NODE_MINOR" -ge 6 ]; } || { [ "$NODE_MAJOR" -eq 22 ] && [ "$NODE_MINOR" -ge 18 ]; }; }

command -v "$PM" >/dev/null || die "Package manager '$PM' tidak tersedia di image ini."

# ---------- 1. git pull ----------
if [ -d .git ] && [ "${AUTO_UPDATE:-0}" = "1" ]; then
    log "git pull"
    git pull || log "git pull gagal, lanjut dengan kode yang ada"
fi

# ---------- 2. paket tambahan / hapus paket ----------
pm_add() {
    case "$PM" in
        npm)  npm install --no-audit --no-fund "$@" ;;
        pnpm) pnpm add "$@" ;;
        yarn) yarn add "$@" ;;
        bun)  bun add "$@" ;;
    esac
}
pm_remove() {
    case "$PM" in
        npm)  npm uninstall --no-audit --no-fund "$@" ;;
        pnpm) pnpm remove "$@" ;;
        yarn) yarn remove "$@" ;;
        bun)  bun remove "$@" ;;
    esac
}
if [ -n "${NODE_PACKAGES:-}" ]; then
    read -ra pkgs <<< "$NODE_PACKAGES"
    log "$PM add ${pkgs[*]}"
    pm_add "${pkgs[@]}" || die "Gagal memasang paket tambahan."
fi
if [ -n "${UNNODE_PACKAGES:-}" ]; then
    read -ra pkgs <<< "$UNNODE_PACKAGES"
    log "$PM remove ${pkgs[*]}"
    pm_remove "${pkgs[@]}" || die "Gagal menghapus paket."
fi

# ---------- 3. install dependencies (hanya jika package.json/lockfile berubah) ----------
install_deps() {
    # shellcheck disable=SC2086  # INSTALL_FLAGS memang harus di-split
    case "$PM" in
        npm)
            if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
                npm ci --no-audit --no-fund ${INSTALL_FLAGS:-} || npm install --no-audit --no-fund ${INSTALL_FLAGS:-}
            else
                npm install --no-audit --no-fund ${INSTALL_FLAGS:-}
            fi ;;
        pnpm)
            if [ -f pnpm-lock.yaml ]; then
                pnpm install --frozen-lockfile ${INSTALL_FLAGS:-} || pnpm install ${INSTALL_FLAGS:-}
            else
                pnpm install ${INSTALL_FLAGS:-}
            fi ;;
        yarn)
            if [ -f .yarnrc.yml ]; then
                yarn install --immutable ${INSTALL_FLAGS:-} || yarn install ${INSTALL_FLAGS:-}
            elif [ -f yarn.lock ]; then
                yarn install --frozen-lockfile ${INSTALL_FLAGS:-} || yarn install ${INSTALL_FLAGS:-}
            else
                yarn install ${INSTALL_FLAGS:-}
            fi ;;
        bun)
            if [ -f bun.lock ] || [ -f bun.lockb ]; then
                bun install --frozen-lockfile ${INSTALL_FLAGS:-} || bun install ${INSTALL_FLAGS:-}
            else
                bun install ${INSTALL_FLAGS:-}
            fi ;;
    esac
}
deps_hash() {
    for f in package.json package-lock.json npm-shrinkwrap.json pnpm-lock.yaml yarn.lock .yarnrc.yml bun.lock bun.lockb; do
        [ -f "$f" ] && sha256sum "$f"
    done | sha256sum | cut -d' ' -f1
}
if [ -f package.json ]; then
    stamp="node_modules/.egg-deps-hash"
    current="$(deps_hash)|$PM|${INSTALL_FLAGS:-}|$NODE_MAJOR"
    if [ ! -d node_modules ] || [ "$(cat "$stamp" 2>/dev/null)" != "$current" ]; then
        log "install dependencies ($PM)"
        install_deps || die "Install dependencies gagal."
        mkdir -p node_modules
        # hash dihitung ulang: install bisa membuat/mengubah lockfile
        echo "$(deps_hash)|$PM|${INSTALL_FLAGS:-}|$NODE_MAJOR" > "$stamp"
    else
        log "dependencies sudah up-to-date, install dilewati"
    fi
fi

# ---------- 4. batas heap otomatis ----------
# SERVER_MEMORY (MB) diisi Wings; 0 = tanpa batas.
if [ "${AUTO_MEMORY_LIMIT:-1}" = "1" ] && [[ "${SERVER_MEMORY:-}" =~ ^[0-9]+$ ]] && [ "$SERVER_MEMORY" -gt 0 ] \
    && [[ "${NODE_OPTIONS:-}" != *max-old-space-size* ]]; then
    heap=$(( SERVER_MEMORY * 85 / 100 ))
    [ "$heap" -lt 128 ] && heap=128
    export NODE_OPTIONS="${NODE_OPTIONS:+$NODE_OPTIONS }--max-old-space-size=$heap"
    log "heap limit Node.js: ${heap} MB (85% dari ${SERVER_MEMORY} MB)"
fi

# ---------- 5. tentukan cara menjalankan ----------
APP_ARGS=()
[ -n "${NODE_ARGS:-}" ] && read -ra APP_ARGS <<< "$NODE_ARGS"

has_script() {
    [ -f package.json ] && node -e 'const p=require("./package.json");process.exit(p.scripts&&p.scripts[process.argv[1]]?0:1)' "$1"
}

run_script() {
    local s="$1"
    log "menjalankan: $PM run $s ${APP_ARGS[*]}"
    case "$PM" in
        npm) exec npm run "$s" ${APP_ARGS[0]:+--} "${APP_ARGS[@]}" ;;
        *)   exec "$PM" run "$s" "${APP_ARGS[@]}" ;;
    esac
}

detect_main() {
    local m
    m=$(node -e 'try{console.log(require("./package.json").main||"")}catch(e){}' 2>/dev/null)
    if [ -n "$m" ] && [ -f "$m" ]; then echo "$m"; return; fi
    for m in index.js index.mjs index.cjs index.ts src/index.js src/index.ts main.js bot.js app.js server.js; do
        [ -f "$m" ] && { echo "$m"; return; }
    done
}

run_file() {
    [ -f "$MAIN" ] || die "File utama '$MAIN' tidak ditemukan di $APP_DIR."
    local envflag=() cmd
    if node_gte 20 6 && [ -f .env ]; then
        envflag=(--env-file=.env)
        log "memuat .env lewat --env-file"
    fi
    case "$MAIN" in
        *.ts|*.mts|*.cts)
            if [ "$TS_RUNNER" = "node" ]; then
                ts_native || die "Node $(node -v) belum mendukung TypeScript bawaan (butuh 22.18+). Pakai TS_RUNNER=tsx."
                cmd=(node "${envflag[@]}")
                [ "$RUN_MODE" = "dev" ] && cmd+=(--watch)
            else
                cmd=(tsx)
                [ "$RUN_MODE" = "dev" ] && cmd+=(watch)
                cmd+=("${envflag[@]}")
            fi ;;
        *)
            cmd=(node "${envflag[@]}")
            [ "$RUN_MODE" = "dev" ] && cmd+=(--watch) ;;
    esac
    log "menjalankan: ${cmd[*]} $MAIN ${APP_ARGS[*]}"
    exec "${cmd[@]}" "$MAIN" "${APP_ARGS[@]}"
}

case "$RUN_MODE" in
    start)
        has_script start || die "RUN_MODE=start, tapi package.json tidak punya script 'start'."
        run_script start ;;
    dev)
        if [ -z "$MAIN" ] && has_script dev; then run_script dev; fi
        [ -n "$MAIN" ] || MAIN=$(detect_main)
        [ -n "$MAIN" ] || die "Tidak ada script 'dev' maupun file utama. Isi MAIN_FILE."
        run_file ;;
    auto)
        if [ -n "$MAIN" ]; then run_file; fi
        if has_script start; then run_script start; fi
        MAIN=$(detect_main)
        [ -n "$MAIN" ] || die "Tidak ada MAIN_FILE, script 'start', maupun file bawaan (index.js, src/index.ts, ...). Isi MAIN_FILE."
        run_file ;;
    *)
        die "RUN_MODE '$RUN_MODE' tidak dikenal (pakai: auto, start, dev)." ;;
esac
