FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NODE_ENV=production
ENV PORT=10000

WORKDIR /app

# System packages
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

# yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o /usr/local/bin/yt-dlp \
    && chmod +x /usr/local/bin/yt-dlp

# ------------------------------------------------
# ROOT DEPENDENCIES
# Ignore postinstall because we handle everything
# manually below.
# ------------------------------------------------

COPY package.json package-lock.json ./

RUN npm install --omit=dev --ignore-scripts

# ------------------------------------------------
# CLIENT DEPENDENCIES
# ------------------------------------------------

COPY client/package.json client/package-lock.json ./client/

RUN npm install --prefix client --ignore-scripts

# ------------------------------------------------
# PYTHON DEPENDENCIES
# ------------------------------------------------

COPY server/requirements.txt ./server/

RUN pip3 install --no-cache-dir \
    --break-system-packages \
    -r server/requirements.txt

# ------------------------------------------------
# COPY SOURCE
# ------------------------------------------------

COPY . .

# ------------------------------------------------
# BUILD FRONTEND
# ------------------------------------------------

RUN npm --prefix client run build

# ------------------------------------------------
# CREATE REQUIRED DIRECTORIES
# ------------------------------------------------

RUN mkdir -p \
    server/uploads \
    server/uploads/previews \
    server/exports \
    server/samples \
    server/assets/sfx \
    && chmod -R 777 \
    server/uploads \
    server/exports \
    server/samples

# ------------------------------------------------
# RENDER PORT
# ------------------------------------------------

EXPOSE 10000

CMD ["node", "server/server.js"]