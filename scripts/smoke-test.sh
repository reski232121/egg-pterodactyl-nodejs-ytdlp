#!/usr/bin/env bash
# Smoke test image Docker. Pemakaian: scripts/smoke-test.sh <image> <node-major> <full|slim>
set -euo pipefail

image="${1:?image wajib diisi}"
major="${2:?node major wajib diisi}"
variant="${3:-full}"

fail() { echo "::error::SMOKE TEST GAGAL: $*"; exit 1; }
run() { docker run --rm --entrypoint bash "$image" -c "$1"; }

echo "== versi Node.js"
actual=$(run 'node -p "process.versions.node.split(\".\")[0]"')
[ "$actual" = "$major" ] || fail "Node major $actual, diharapkan $major"

echo "== tools"
run 'yt-dlp --version && ffmpeg -version | head -n1 && python3 --version && git --version && tini --version' \
    || fail "yt-dlp/ffmpeg/python/git/tini"
run 'cloudflared --version' || fail "cloudflared"
run 'npm -v && pnpm -v && yarn -v && bun -v && tsx --version | head -n1' || fail "package manager / tsx"
run 'yt-dlp --list-impersonate-targets | grep -qi curl_cffi' || fail "curl-cffi (impersonate) tidak aktif"

echo "== varian: $variant"
if [ "$variant" = "full" ]; then
    run 'gcc --version | head -n1 && make --version | head -n1' || fail "build tools hilang di varian full"
else
    run '! command -v gcc' || fail "varian slim seharusnya tanpa gcc"
fi

echo "== entrypoint + STARTUP"
out=$(docker run --rm -e AUTO_UPDATE_YTDLP=0 -e STARTUP='echo smoke-ok' "$image")
echo "$out" | grep -q 'smoke-ok' || fail "entrypoint tidak menjalankan STARTUP"

echo "== cloudflare tunnel (token palsu: harus mencoba start, token tidak bocor ke aplikasi)"
fake='eyJhIjoiZmFrZSIsInQiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDAiLCJzIjoiYWJjIn0='
out=$(docker run --rm -e AUTO_UPDATE_YTDLP=0 -e CLOUDFLARE_TUNNEL_TOKEN="cloudflared service install $fake" \
    -e STARTUP='sleep 6; env' "$image" 2>&1)
echo "$out" | grep -q '\[cloudflared\]' || fail "cloudflared tidak dijalankan: $out"
echo "$out" | grep -q 'memulai tunnel' || fail "log start tunnel tidak ada"
if echo "$out" | grep -q "$fake"; then fail "token bocor ke log/environment aplikasi"; fi

echo "== start-app (script start, batas heap, argumen)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/package.json" <<'JSON'
{ "name": "smoke", "scripts": { "start": "node index.js" } }
JSON
echo 'console.log("app-ok", process.env.NODE_OPTIONS || "")' > "$tmp/index.js"
chmod -R a+rwX "$tmp"
out=$(docker run --rm -v "$tmp:/home/container" \
    -e AUTO_UPDATE_YTDLP=0 -e SERVER_MEMORY=512 -e STARTUP=start-app "$image")
echo "$out" | grep -q 'app-ok --max-old-space-size=435' || fail "start-app / batas heap: $out"

echo "SMOKE TEST OK ($image)"
