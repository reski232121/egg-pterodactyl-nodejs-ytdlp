# Pterodactyl Node.js + yt-dlp + FFmpeg

Docker image dan Pterodactyl egg untuk Node.js 20 LTS dengan yt-dlp, FFmpeg, Python3, dan build tools.

## Fitur

✅ Node.js 20 LTS  
✅ yt-dlp (1000+ platform support)  
✅ FFmpeg (audio/video processing)  
✅ Python3 + pip  
✅ Build tools (gcc, g++, make)  
✅ TypeScript support  
✅ Git included  

## Setup

### 1. Clone Repository
```bash
git clone https://github.com/yourusername/pterodactyl-nodejs-ytdlp.git
cd pterodactyl-nodejs-ytdlp
```

### 2. Build Image
```bash
docker build -t yourusername/pterodactyl-nodejs-ytdlp:latest .
```

### 3. Push ke Registry

**GitHub Container Registry (GHCR):**
```bash
docker login ghcr.io
docker push ghcr.io/yourusername/pterodactyl-nodejs-ytdlp:latest
```

**Docker Hub:**
```bash
docker login
docker push yourusername/pterodactyl-nodejs-ytdlp:latest
```

### 4. Import ke Pterodactyl

1. Admin Panel → Nests & Eggs
2. Import Egg → Upload `egg-nodejs-ytdlp.json`
3. Update Docker image path
4. Create server

## Startup Commands

```bash
npm start
npm start -- --port {{SERVER_PORT}}
npx tsx src/index.ts
```

## Tools Available

```bash
node -v          # Node.js
npm -v           # npm
python3 --version # Python
yt-dlp --version # yt-dlp
ffmpeg -version  # FFmpeg
git --version    # Git
```

## Use Cases

- Discord Music Bots
- Media Downloaders
- Video Processors
- Web Servers
- Node.js Applications

## Requirements

- Docker
- GitHub account (untuk push)

## License

MIT
