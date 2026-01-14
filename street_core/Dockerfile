# ========================================
# STREETCORE FRONTEND - Flutter Web
# ========================================
# Multi-stage build para optimizar tamaño
# Stage 1: Builder (Flutter)
# Stage 2: Runtime (Nginx)
# ========================================

# ========================================
# STAGE 1: FLUTTER BUILDER
# ========================================
FROM debian:stable-slim AS builder

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Instalar Flutter
ENV FLUTTER_VERSION=3.24.5
ENV FLUTTER_HOME=/opt/flutter
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME}
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Pre-download Flutter dependencies
RUN flutter precache --web

# Configurar directorio de trabajo
WORKDIR /app

# Copiar pubspec para cachear dependencias
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar código fuente
COPY . .

# Build para web en modo release
# --release: Optimizado para producción
# --web-renderer html: Compatible con todos los navegadores
RUN flutter build web --release --web-renderer html

# ========================================
# STAGE 2: NGINX RUNTIME
# ========================================
FROM nginx:1.27-alpine

# Instalar wget para healthcheck
RUN apk add --no-cache wget

# Copiar archivos build de Flutter
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copiar configuración de Nginx optimizada para Cloudflare
COPY nginx.conf /etc/nginx/nginx.conf
COPY cloudflare.conf /etc/nginx/conf.d/cloudflare.conf

# Crear archivo de versión para cache busting
RUN echo "BETA-$(date +%Y%m%d-%H%M%S)" > /usr/share/nginx/html/version.txt

# Exponer puerto 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:80 || exit 1

# Comando de inicio
CMD ["nginx", "-g", "daemon off;"]
