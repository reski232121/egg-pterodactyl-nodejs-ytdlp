# Pterodactyl Node.js + yt-dlp + FFmpeg

Docker image dan Pterodactyl egg untuk Node.js (18–26) dengan yt-dlp, FFmpeg, Python3, dan build tools.
Image otomatis di-build oleh GitHub Actions dan dipush ke GHCR.

## Fitur

✅ Node.js 18 – 26 (disarankan LTS: 22, 24, 26)
✅ yt-dlp + yt-dlp-ejs (Node.js dipakai sebagai JS runtime untuk YouTube)
✅ FFmpeg (audio/video processing)
✅ Python3 + pip
✅ Build tools (gcc, g++, make)
✅ TypeScript (`tsx`, `ts-node`)
✅ Git, SQLite
✅ Multi-arch: `linux/amd64` dan `linux/arm64`
✅ Opsi auto-update yt-dlp setiap server start (`AUTO_UPDATE_YTDLP=1`)

> **Catatan:** Node.js 18, 19, 20, 21, 23, dan 25 sudah End-of-Life dan tidak menerima patch keamanan. Pakai 22, 24, atau 26 untuk server baru.

## Tag image

| Tag | Isi |
| --- | --- |
| `ghcr.io/reski232121/egg-pterodactyl-nodejs-ytdlp:node-<versi>` | Node.js versi tertentu, mis. `node-24` |
| `ghcr.io/reski232121/egg-pterodactyl-nodejs-ytdlp:latest` | Sama dengan `node-24` |

Ganti `reski232121/egg-pterodactyl-nodejs-ytdlp` dengan `<username>/<nama-repo>` milikmu jika di-fork.

## Setup

1. Push repo ke GitHub (branch `main`/`master`). Workflow `.github/workflows/docker.yml` akan build semua versi.
2. Pastikan package di GHCR berstatus **Public** (Packages → Package settings → Change visibility), supaya Wings bisa pull tanpa login.
3. Admin Panel → Nests & Eggs → Import Egg → upload `egg-nodejs-ytdlp.json`.
4. Jika repo bukan milik `reski232121`, edit daftar Docker image di egg.
5. Buat server.

## Build manual (opsional)

```bash
docker build -t ghcr.io/<username>/<repo>:node-24 ./nodejs/24
docker push ghcr.io/<username>/<repo>:node-24
```

## Variabel egg

| Variabel | Fungsi |
| --- | --- |
| `MAIN_FILE` | File utama (`index.js`, atau `src/index.ts` untuk TypeScript via tsx) |
| `NODE_ARGS` | Argumen tambahan aplikasi |
| `NODE_PACKAGES` / `UNNODE_PACKAGES` | Install / uninstall package npm saat start |
| `GIT_ADDRESS`, `BRANCH`, `USERNAME`, `ACCESS_TOKEN` | Clone repo saat instalasi |
| `AUTO_UPDATE` | `git pull` setiap start |
| `AUTO_UPDATE_YTDLP` | Update yt-dlp setiap start |

## Tools tersedia

```bash
node -v
npm -v
python3 --version
yt-dlp --version
ffmpeg -version
git --version
```

## License

MIT
