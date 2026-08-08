# unierp-mobile — Flutter Web Client Application
#
# Multi-stage Dockerfile:
# 1. Builder: Flutter stable SDK builds static web bundle
# 2. Runner: Lightweight Nginx Alpine serves static files on port 8080

# ── Stage 1: Build Flutter Web ─────────────────────────────────────────────
FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils zip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git ${FLUTTER_HOME} \
    && flutter config --no-analytics \
    && flutter config --enable-web

WORKDIR /app
COPY . .

ARG API_BASE_URL=http://api:3001
RUN flutter pub get && \
    flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ── Stage 2: Serve with Nginx ─────────────────────────────────────────────
FROM nginx:alpine AS runner

COPY --from=builder /app/build/web /usr/share/nginx/html

RUN printf 'server {\n    listen 8080;\n    server_name localhost;\n    location / {\n        root /usr/share/nginx/html;\n        index index.html index.htm;\n        try_files $uri $uri/ /index.html;\n    }\n}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
