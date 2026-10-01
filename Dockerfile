FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NODE_ENV=production

WORKDIR /app

# System dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
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

# Install yt-dlp
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp \
    -o /usr/local/bin/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp

# Copy package files first
COPY package.json package-lock.json ./
COPY client/package.json client/package-lock.json ./client/
COPY server/requirements.txt ./server/

# Install client dependencies
RUN npm ci --prefix client

# Install root/server dependencies
# npm install is intentional because this repo's package.json
# has a postinstall script that prepares the client.
RUN npm install --omit=dev

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    -r server/requirements.txt

# Copy application source
COPY . .

# Build frontend
RUN npm --prefix client run build

# Create runtime directories
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

# Render provides PORT; server.js reads process.env.PORT
ENV PORT=10000

EXPOSE 10000

CMD ["node", "server/server.js"]