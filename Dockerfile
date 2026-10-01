FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV NODE_ENV=production
ENV PORT=10000

WORKDIR /app

# System dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
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
    && chmod a+rx /usr/local/bin/yt-dlp

# Root Node dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Client dependencies
COPY client/package*.json ./client/
RUN npm ci --prefix client

# Python virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Python dependencies
COPY server/requirements.txt ./server/
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r server/requirements.txt

# Copy application
COPY . .

# Build React frontend
RUN npm --prefix client run build

# Runtime directories
RUN mkdir -p \
    server/uploads/previews \
    server/exports \
    server/samples \
    server/assets/sfx \
    && chmod -R 777 server/uploads server/exports server/samples

EXPOSE 10000

CMD ["node", "server/server.js"]