FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NODE_ENV=production
ENV PORT=10000

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    ffmpeg \
    fontconfig \
    fonts-noto-color-emoji \
    fonts-freefont-ttf \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o /usr/local/bin/yt-dlp \
    && chmod +x /usr/local/bin/yt-dlp

# Root dependencies — don't run postinstall
COPY package*.json ./
RUN npm install --omit=dev --ignore-scripts

# Client dependencies — don't run scripts yet
COPY client/package*.json ./client/
RUN cd client && npm install --ignore-scripts

# Python dependencies
COPY server/requirements.txt ./server/
RUN pip3 install --break-system-packages --no-cache-dir \
    -r server/requirements.txt

# Application source
COPY . .

# Frontend
RUN cd client && npm run build

# Runtime folders
RUN mkdir -p \
    server/uploads/previews \
    server/exports \
    server/samples \
    server/assets/sfx \
    && chmod -R 777 \
    server/uploads \
    server/exports \
    server/samples

EXPOSE 10000

CMD ["node", "server/server.js"]