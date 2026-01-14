# ========================================
# STREETCORE BACKEND - Go/Gin API
# ========================================
# Multi-stage build para optimizar tamaño
# Stage 1: Builder
# Stage 2: Runtime
# ========================================

# ========================================
# STAGE 1: BUILDER
# ========================================
FROM golang:1.25.5-alpine AS builder

# Instalar dependencias de build
RUN apk add --no-cache git ca-certificates tzdata

# Crear directorio de trabajo
WORKDIR /build

# Copiar go.mod y go.sum para cachear dependencias
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Copiar código fuente
COPY . .

# Build optimizado para producción
# CGO_ENABLED=0: Binario estático sin dependencias C
# -ldflags="-s -w": Strip debug info para reducir tamaño
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-s -w" \
    -o streetcore-api \
    main.go

# ========================================
# STAGE 2: RUNTIME
# ========================================
FROM alpine:3.21

# Instalar CA certificates y timezone data
RUN apk --no-cache add ca-certificates tzdata wget

# Crear usuario no-root para seguridad
RUN addgroup -g 1000 streetcore && \
    adduser -D -u 1000 -G streetcore streetcore

# Configurar directorios
WORKDIR /app

# Crear directorios necesarios
RUN mkdir -p /app/uploads /app/logs && \
    chown -R streetcore:streetcore /app

# Copiar binario desde builder
COPY --from=builder /build/streetcore-api /app/streetcore-api

# Cambiar a usuario no-root
USER streetcore

# Exponer puerto 3000
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

# Comando de inicio
CMD ["/app/streetcore-api"]
