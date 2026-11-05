# Pterodactyl Node.js + yt-dlp + FFmpeg

[![Docker Build & Push](https://github.com/reski232121/egg-pterodactyl-nodejs-ytdlp/actions/workflows/docker.yml/badge.svg)](https://github.com/reski232121/egg-pterodactyl-nodejs-ytdlp/actions/workflows/docker.yml)

Docker image dan egg Pterodactyl untuk aplikasi Node.js (bot Discord musik, media downloader, dll.) lengkap dengan yt-dlp dan FFmpeg.
Image dibuild otomatis oleh GitHub Actions dan dipush ke GHCR.

## Fitur

- Node.js 22, 24, 26 (LTS/terbaru), multi-arch `linux/amd64` + `linux/arm64`
- yt-dlp + yt-dlp-ejs (Node.js sebagai JS runtime untuk YouTube) + **curl-cffi** (`--impersonate chrome`)
- FFmpeg, Python 3, Git, SQLite
- **Cloudflare Tunnel** (`cloudflared`): cukup isi token di egg, tanpa buka port
- Package manager: **npm, pnpm, yarn, bun** (dipilih lewat variabel egg)
- TypeScript: `tsx` atau TypeScript bawaan Node (22.18+)
- Startup modern: tini sebagai init (Stop/Restart bersih), batas heap otomatis, install dependencies hanya saat berubah, deteksi entry point otomatis

## Tag image

| Tag | Mengarah ke |
| --- | --- |
| `node-22`, `node-24`, `node-26` | Versi major tertentu |
| `node-lts` | Node.js LTS pilihan repo (saat ini 24) |
| `node-current` | Node.js terbaru (saat ini 26) |
| `latest` | Sama dengan `node-24` |
| `v1.2.3-node-24` | Tag rilis Git (jika repo memakai tag `v*`) |

Semua image sudah termasuk build tools (gcc, make, python3-dev, dll.) untuk kompilasi native module.

Alias diatur lewat `LATEST_NODE`, `LTS_NODE`, `CURRENT_NODE` di bagian `env` workflow.

**Versi EOL (18, 20, 21, 23, 25)** tidak ikut build otomatis. Jalankan manual: *Actions → Docker Build & Push → Run workflow → centang `include_eol`*. Versi EOL tidak menerima patch keamanan, jadi gunakan 22, 24, atau 26 untuk server baru.

Ganti `reski232121/egg-pterodactyl-nodejs-ytdlp` dengan `<username>/<repo>` milikmu jika di-fork.

## Setup

1. Push repo ke GitHub (branch `main`/`master`). Workflow akan build semua versi.
2. Ubah package GHCR jadi **Public** (Packages → Package settings → Change visibility), agar Wings bisa pull tanpa login.
3. Admin Panel → Nests & Eggs → Import Egg → upload `egg-nodejs-ytdlp.json`.
4. Jika repo bukan milik `reski232121`, edit daftar Docker image di egg.
5. Buat server.

**Pelican Panel:** Pelican dapat mengimpor egg format PTDL_v2 ini langsung. Egg ini hanya memakai fitur standar, tetapi belum diuji di Pelican; sesuaikan jika ada perbedaan.

## Cara kerja startup

Startup egg hanya `start-app`. Urutannya:

1. `entrypoint.sh`: set timezone, update yt-dlp (opsional), tulis config yt-dlp, lalu `exec tini`
2. `start-app`: `git pull` (opsional) → paket tambahan → install dependencies (dilewati jika `package.json`/lockfile tidak berubah) → atur batas heap → jalankan aplikasi

Entry point (mode `auto`):

1. `MAIN_FILE` jika diisi
2. script `start` di `package.json`
3. field `main` di `package.json`
4. `index.js`, `index.ts`, `src/index.*`, `main.js`, `bot.js`, `app.js`, `server.js`

File `.env` otomatis dimuat lewat `--env-file` (Node 20.6+) untuk mode file. Untuk file `.ts`, `TS_RUNNER=tsx` (default, paling kompatibel) atau `node` (TypeScript bawaan, tanpa enum/path alias).

## Variabel egg

| Variabel | Default | Fungsi |
| --- | --- | --- |
| `MAIN_FILE` | kosong | File utama; kosong = deteksi otomatis |
| `RUN_MODE` | `auto` | `auto`, `start` (script package.json), `dev` (`--watch`) |
| `PACKAGE_MANAGER` | `npm` | `npm`, `pnpm`, `yarn`, `bun` |
| `TS_RUNNER` | `tsx` | `tsx` atau `node` |
| `NODE_ENV` | `production` | Catatan: `production` melewati devDependencies; pakai `INSTALL_FLAGS=--include=dev` jika perlu |
| `TZ` | `UTC` | Mis. `Asia/Jakarta` |
| `NODE_OPTIONS` | kosong | Flag Node.js tambahan |
| `AUTO_MEMORY_LIMIT` | `1` | `--max-old-space-size` = 85% RAM server |
| `INSTALL_FLAGS` | kosong | Mis. `--ignore-scripts` |
| `NODE_ARGS` | kosong | Argumen untuk aplikasi |
| `NODE_PACKAGES` / `UNNODE_PACKAGES` | kosong | Tambah / hapus paket saat start |
| `AUTO_UPDATE` | `0` | `git pull` setiap start |
| `AUTO_UPDATE_YTDLP` | `1` | Update yt-dlp setiap start |
| `YTDLP_CHANNEL` | `stable` | `stable` atau `nightly` |
| `YTDLP_COOKIES` | kosong | Path file cookies, mis. `cookies.txt` |
| `CLOUDFLARE_TUNNEL_TOKEN` | kosong | Token Cloudflare Tunnel; kosong = tunnel mati |
| `CLOUDFLARE_TUNNEL_PROTOCOL` | `auto` | `auto`, `quic`, atau `http2` |
| `GIT_ADDRESS`, `BRANCH`, `USERNAME`, `ACCESS_TOKEN`, `USER_UPLOAD` | | Clone repo saat instalasi |

Package manager hanya dipakai untuk install dependencies dan paket tambahan. Aplikasi tetap dijalankan dengan Node.js.

## Cloudflare Tunnel

Dengan tunnel, aplikasi web/API di server bisa diakses lewat domain Cloudflare tanpa membuka port atau menampilkan IP server.

1. Di dashboard Cloudflare: **Zero Trust → Networks → Tunnels → Create a tunnel → Cloudflared**.
2. Salin **token** (string panjang diawali `eyJ`). Boleh juga menempel seluruh perintah `cloudflared service install eyJ...`; token diambil otomatis.
3. Tempel di variabel egg **`CLOUDFLARE_TUNNEL_TOKEN`**, lalu restart server.
4. Di tab **Public Hostname** tunnel, tambahkan hostname dengan service `http://localhost:<port>`. Gunakan port yang dipakai aplikasimu (biasanya port allocation server, tersedia di aplikasi sebagai `SERVER_PORT`).

Catatan:

- Tunnel dijalankan oleh `entrypoint.sh`, jadi tetap aktif walau `STARTUP` diubah. Log-nya tampil di console dengan prefix `[cloudflared]`.
- Token dikirim ke cloudflared lewat environment, tidak muncul di daftar proses, dan **tidak diteruskan ke aplikasi Node.js**.
- Jika tunnel mati, dijalankan ulang otomatis. Jika gagal 5x berturut-turut dalam waktu singkat (biasanya token salah), tunnel dihentikan dan log menyarankan memeriksa token.
- Jika koneksi tidak stabil atau jaringan host memblokir UDP, set `CLOUDFLARE_TUNNEL_PROTOCOL=http2`.
- Tunnel Cloudflare untuk HTTP/HTTPS. Trafik non-HTTP (mis. game server UDP) tidak cocok memakai fitur ini.
- Binary `cloudflared` diunduh dari rilis resmi GitHub Cloudflare saat build dan ikut diperbarui lewat rebuild mingguan. Pastikan token dijaga rahasia; siapa pun yang punya akses ke variabel egg dapat melihatnya.

## yt-dlp

- Config otomatis di `~/.config/yt-dlp/config` (cache persisten di `~/.cache/yt-dlp`, cookies jika `YTDLP_COOKIES` diisi). Config ini dibuat ulang tiap start selama baris `# managed-by-egg` masih ada; hapus baris itu untuk mengatur sendiri.
- Impersonation untuk situs yang memblokir klien biasa: `yt-dlp --impersonate chrome <url>` (cek target: `yt-dlp --list-impersonate-targets`).
- Update lewat egg (`AUTO_UPDATE_YTDLP=1`) dipasang di folder pengguna, jadi tidak perlu rebuild image.

## CI/CD dan keamanan

- **Rebuild mingguan** (Senin 03:00 UTC) untuk patch Debian, Node.js, dan yt-dlp terbaru.
- **Trivy**: laporan CVE CRITICAL/HIGH di log build (tidak memblokir).
- **Provenance + SBOM** diaktifkan pada image yang dipush.
- **Cosign keyless signing**. Verifikasi:

  ```bash
  cosign verify ghcr.io/<username>/<repo>:node-24 \
    --certificate-identity-regexp 'https://github.com/<username>/<repo>/.*' \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com
  ```

## Contoh konfigurasi

**Bot Discord musik (TypeScript, pnpm):**
`PACKAGE_MANAGER=pnpm`, `MAIN_FILE=src/index.ts`, `TZ=Asia/Jakarta`, `AUTO_UPDATE_YTDLP=1`, `YTDLP_CHANNEL=stable`

**Media downloader (JavaScript, npm):**
kosongkan `MAIN_FILE` (pakai script `start`), `YTDLP_COOKIES=cookies.txt`

## Build manual

```bash
docker build -t ghcr.io/<username>/<repo>:node-24 ./nodejs/24
```

## License

MIT
