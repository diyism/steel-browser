# 使用多阶段构建
ARG NODE_VERSION=20.12.0

# Base stage for shared dependencies
FROM node:${NODE_VERSION}-slim AS base
WORKDIR /app
ENV NODE_ENV="production"
ENV PUPPETEER_CACHE_DIR=/app/.cache
ENV DISPLAY=:10
ENV PATH="/usr/bin:/app/selenium/driver:${PATH}"
ENV CHROME_BIN=/usr/bin/google-chrome-stable
ENV CHROME_PATH=/usr/bin/google-chrome-stable

# API Build stage
FROM base AS api-build
RUN apt-get update -qq && \
    apt-get install -y build-essential pkg-config python-is-python3 xvfb
COPY api/package*.json ./api/
WORKDIR /app/api
RUN npm ci --include=dev
COPY api/ ./
RUN npm run build
RUN npm prune --omit=dev

# UI Build stage
FROM node:18 AS ui-build
WORKDIR /app/ui
COPY ui/package*.json ./
RUN npm install
COPY ui/ ./
RUN npm run build

# Final stage
FROM base
WORKDIR /app

# Install Chrome and other dependencies
RUN apt-get update \
    && apt-get install -y wget nginx gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && apt-get update \
    && apt-get install -y fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
    libxss1 xvfb curl unzip default-jre dbus dbus-x11 --no-install-recommends

# Install Chrome
RUN curl -o chrome.deb https://mirror.cs.uchicago.edu/google-chrome/pool/main/g/google-chrome-stable/google-chrome-stable_128.0.6613.119-1_amd64.deb \
    && apt-get install -y ./chrome.deb \
    && rm chrome.deb

# Install ChromeDriver
RUN mkdir -p /selenium/driver \
    && curl -o chromedriver.zip https://storage.googleapis.com/chrome-for-testing-public/128.0.6613.119/linux64/chromedriver-linux64.zip \
    && unzip chromedriver.zip -d /tmp \
    && mv /tmp/chromedriver-linux64/chromedriver /selenium/driver/chromedriver \
    && rm -rf chromedriver.zip /tmp/chromedriver-linux64 \
    && chmod +x /selenium/driver/chromedriver \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy built applications
COPY --from=api-build /app/api /app/api
COPY --from=ui-build /app/ui /app/ui

# Copy configuration files
COPY nginx.conf /app/nginx.conf
COPY api/entrypoint.sh /app/api/entrypoint.sh
COPY combined-entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/api/entrypoint.sh /app/entrypoint.sh

# Environment variables
ENV HOST_IP=localhost
ENV DISPLAY=:10
ENV DBUS_SESSION_BUS_ADDRESS=autolaunch:
ENV VITE_API_URL=/api
ENV VITE_WS_URL=ws://localhost/api
ENV VITE_OPENAPI_URL=/api/documentation/json

# Expose ports
EXPOSE 9223
EXPOSE 5173
EXPOSE 3000
EXPOSE 10000

# Start both services
ENTRYPOINT ["/app/entrypoint.sh"]
