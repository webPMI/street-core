# StreetCore - BETA Deployment Guide

## Descripción

Entorno Docker completo para desplegar StreetCore en **versión BETA** con:

- **Backend** Go/Gin (puerto 3000)
- **Frontend** Flutter Web (puerto 80)
- **MongoDB** 7.0 con volúmenes persistentes
- **Cloudflare** Headers y configuración CDN/WAF

## Requisitos Previos

### Software Necesario

- **Docker** 20.10+ ([Instalar Docker](https://docs.docker.com/get-docker/))
- **Docker Compose** 2.0+ (incluido en Docker Desktop)

### Hardware Mínimo

- **CPU**: 2 cores
- **RAM**: 4 GB
- **Disco**: 10 GB libres

---

## Configuración Inicial

### 1. Configurar Variables de Entorno

```bash
# Copiar archivo de configuración BETA
cp .env.beta .env

# Editar según tu dominio
nano .env.beta
```

**Variables CRÍTICAS a configurar**:

```env
# Dominios (cambiar por tus dominios reales)
BASE_URL=https://api-beta.streetcore.com
FRONTEND_URL=https://beta.streetcore.com

# Seguridad (generar nuevos valores)
JWT_SECRET=<ejecutar: openssl rand -hex 32>
OAUTH_ENCRYPTION_KEY=<ejecutar: openssl rand -hex 32>

# Admin (cambiar password en producción)
ADMIN_EMAIL=admin@fitriders.com
ADMIN_PASSWORD=<cambiar por uno seguro>
```

---

## Comandos de Gestión

### Levantar el Entorno

**Linux/macOS**:
```bash
chmod +x start-beta.sh
./start-beta.sh
```

**Windows (PowerShell)**:
```powershell
.\start-beta.ps1
```

**Proceso**:
1. Valida archivo `.env.beta`
2. Verifica Docker
3. Construye contenedores (primera vez: 5-10 minutos)
4. Inicia servicios
5. Espera a que estén saludables

**Resultado**:
```
Frontend:  http://localhost:80
Backend:   http://localhost:3000
MongoDB:   mongodb://localhost:27017
```

---

### Detener Servicios

**Linux/macOS**:
```bash
./stop-beta.sh
```

**Windows**:
```powershell
.\stop-beta.ps1
```

**Datos persistentes se mantienen** (MongoDB, uploads, logs).

---

### Resetear Entorno

**ADVERTENCIA**: Elimina TODOS los datos (MongoDB, uploads, logs).

**Linux/macOS**:
```bash
./reset-beta.sh
```

**Windows**:
```powershell
.\reset-beta.ps1
```

Confirmar con `yes`. Reinicia el entorno con datos frescos.

---

## Estructura de Archivos

```
C:\src\street-core\
├── docker-compose.yml          # Orquestación de servicios
├── .env.beta                   # Variables de entorno BETA
│
├── backend/
│   ├── Dockerfile             # Imagen backend Go
│   └── ... (código fuente)
│
├── street_core/
│   ├── Dockerfile             # Imagen frontend Flutter
│   ├── nginx.conf             # Configuración Nginx
│   ├── cloudflare.conf        # Reglas Cloudflare
│   └── ... (código fuente)
│
├── scripts/
│   └── docker-init/
│       └── 01-init-db.js      # Inicialización MongoDB
│
├── backups/
│   ├── mongodb/               # Backups de base de datos
│   └── uploads/               # Backups de archivos
│
├── start-beta.sh / .ps1       # Scripts de inicio
├── stop-beta.sh / .ps1        # Scripts de detención
└── reset-beta.sh / .ps1       # Scripts de reset
```

---

## Volúmenes Docker

Datos persistentes en volúmenes nombrados:

| Volumen | Contenido | Tamaño Estimado |
|---------|-----------|-----------------|
| `streetcore-mongodb-data-beta` | Base de datos MongoDB | 1-5 GB |
| `streetcore-mongodb-config-beta` | Configuración MongoDB | < 1 MB |
| `streetcore-backend-uploads-beta` | Archivos subidos (imágenes, videos) | Variable |
| `streetcore-backend-logs-beta` | Logs del backend | 50 MB (rotación automática) |

**Ver volúmenes**:
```bash
docker volume ls | grep streetcore
```

**Eliminar volúmenes**:
```bash
docker-compose down -v
```

---

## Configuración de Cloudflare

### DNS Records

Configurar en Cloudflare Dashboard:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `beta.streetcore.com` | `<IP_SERVIDOR>` | ✅ Proxied |
| A | `api-beta.streetcore.com` | `<IP_SERVIDOR>` | ✅ Proxied |

### WAF Rules (Opcional)

**Proteger endpoints sensibles**:

```
(http.host eq "api-beta.streetcore.com" and http.request.uri.path contains "/api/auth/login")
  → Rate Limit: 5 requests / minute
```

### Cache Rules

**Frontend (Flutter Web)**:
- HTML: `no-cache` (siempre última versión)
- Assets (JS/CSS/IMG): `Cache Everything` con TTL 1 año

**Backend**:
- API responses: `Bypass Cache` (no cachear)

### Page Rules

```
beta.streetcore.com/*
  - SSL: Full (strict)
  - Cache Level: Standard
  - Browser Cache TTL: Respect Existing Headers

api-beta.streetcore.com/*
  - SSL: Full (strict)
  - Cache Level: Bypass
```

### Headers Configurados

El archivo `cloudflare.conf` incluye:

- **Security Headers**: X-Frame-Options, CSP, etc.
- **Real IP**: Headers de Cloudflare para obtener IP real
- **Cache-Control**: Directivas optimizadas por tipo de archivo

---

## Monitoreo y Logs

### Ver Logs en Tiempo Real

**Todos los servicios**:
```bash
docker-compose logs -f
```

**Solo backend**:
```bash
docker-compose logs -f backend
```

**Solo frontend**:
```bash
docker-compose logs -f frontend
```

**Solo MongoDB**:
```bash
docker-compose logs -f mongodb
```

### Health Checks

**Backend**:
```bash
curl http://localhost:3000/health
```

**Frontend**:
```bash
curl http://localhost:80/health
```

**MongoDB**:
```bash
docker exec streetcore-mongodb-beta mongosh --eval "db.adminCommand('ping')"
```

### Estado de Servicios

```bash
docker-compose ps
```

---

## Backups

### Backup de MongoDB

**Manual**:
```bash
docker exec streetcore-mongodb-beta mongodump \
  --username=admin \
  --password=admin123 \
  --authenticationDatabase=admin \
  --db=streetcore \
  --out=/backups/backup-$(date +%Y%m%d-%H%M%S)
```

**Resultado**: `backups/mongodb/backup-YYYYMMDD-HHMMSS/`

### Backup de Uploads

```bash
docker cp streetcore-backend-beta:/app/uploads ./backups/uploads-$(date +%Y%m%d-%H%M%S)
```

### Restaurar Backup

**MongoDB**:
```bash
docker exec streetcore-mongodb-beta mongorestore \
  --username=admin \
  --password=admin123 \
  --authenticationDatabase=admin \
  --db=streetcore \
  /backups/<BACKUP_DIR>
```

**Uploads**:
```bash
docker cp ./backups/<BACKUP_DIR> streetcore-backend-beta:/app/uploads
```

---

## Troubleshooting

### Servicios no inician

**Verificar logs**:
```bash
docker-compose logs
```

**Verificar puertos ocupados**:
```bash
# Linux/macOS
netstat -tuln | grep -E ':(80|3000|27017)'

# Windows
netstat -ano | findstr ":80 :3000 :27017"
```

**Solución**: Cambiar puertos en `docker-compose.yml` o liberar puertos.

---

### MongoDB no se conecta

**Verificar conexión**:
```bash
docker exec -it streetcore-mongodb-beta mongosh \
  -u admin -p admin123 --authenticationDatabase admin
```

**Si falla**: Resetear con `./reset-beta.sh`

---

### Backend no encuentra MongoDB

**Verificar red**:
```bash
docker network inspect streetcore-network
```

**Verificar variable**:
```bash
docker exec streetcore-backend-beta env | grep MONGO_URI
```

**Solución**: Verificar que MONGO_URI use `mongodb://mongodb:27017` (no `localhost`).

---

### Frontend no carga

**Verificar build**:
```bash
docker logs streetcore-frontend-beta
```

**Verificar archivos**:
```bash
docker exec streetcore-frontend-beta ls -la /usr/share/nginx/html
```

**Solución**: Rebuild frontend con `docker-compose build frontend --no-cache`

---

### Volúmenes llenos

**Ver uso de disco**:
```bash
docker system df -v
```

**Limpiar contenedores parados**:
```bash
docker container prune
```

**Limpiar imágenes no usadas**:
```bash
docker image prune -a
```

---

## Seguridad

### Cambiar Contraseñas

**Admin User**:
- Cambiar `ADMIN_PASSWORD` en `.env.beta`
- Reiniciar backend: `docker-compose restart backend`

**MongoDB**:
- Cambiar `MONGO_ROOT_PASSWORD` en `.env.beta`
- Resetear entorno: `./reset-beta.sh`

### Actualizar Secrets

```bash
# Generar nuevo JWT_SECRET
openssl rand -hex 32

# Generar nuevo OAUTH_ENCRYPTION_KEY
openssl rand -hex 32

# Actualizar en .env.beta
nano .env.beta

# Reiniciar servicios
docker-compose restart backend
```

### HTTPS

En producción con Cloudflare:
- Cloudflare maneja SSL/TLS (CDN → Servidor)
- Configurar SSL/TLS mode: **Full (strict)**
- Obtener certificado Origin CA desde Cloudflare Dashboard

---

## Comandos Útiles

### Acceder a contenedores

**Backend**:
```bash
docker exec -it streetcore-backend-beta sh
```

**Frontend (Nginx)**:
```bash
docker exec -it streetcore-frontend-beta sh
```

**MongoDB**:
```bash
docker exec -it streetcore-mongodb-beta mongosh \
  -u admin -p admin123 --authenticationDatabase admin
```

### Reiniciar un servicio

```bash
docker-compose restart backend
docker-compose restart frontend
docker-compose restart mongodb
```

### Rebuild sin cache

```bash
docker-compose build --no-cache backend
docker-compose build --no-cache frontend
```

### Ver consumo de recursos

```bash
docker stats
```

---

## Migración a Producción

Cuando BETA esté estable:

1. **Cambiar ENV**:
   ```env
   ENV=production
   TESTING_MODE=false
   ```

2. **Habilitar HSTS**:
   ```env
   ENABLE_HSTS=true
   ```

3. **Configurar S3** (opcional):
   ```env
   MEDIA_STORAGE_TYPE=s3
   MEDIA_S3_BUCKET=<bucket>
   MEDIA_S3_REGION=<region>
   ```

4. **Rate Limiting estricto**:
   ```env
   RATE_LIMIT_GENERAL_RATE=1000
   RATE_LIMIT_AUTH_RATE=10
   ```

5. **Logging estructurado**:
   ```env
   LOG_FORMAT=json
   LOG_LEVEL=warn
   ```

---

## Soporte

**Documentación**:
- [Docker Docs](https://docs.docker.com/)
- [Cloudflare Docs](https://developers.cloudflare.com/)
- [MongoDB Manual](https://www.mongodb.com/docs/)

**Problemas conocidos**:
- Revisar issues en GitHub: `docs/TODO.md`

---

## Credenciales por Defecto

**ADVERTENCIA**: Cambiar en entorno real.

| Servicio | Usuario | Password |
|----------|---------|----------|
| **Admin Panel** | `admin@fitriders.com` | `Aa-1234!` |
| **MongoDB** (root) | `admin` | `admin123` |
| **MongoDB** (app) | `streetcore_app` | `<ver .env.beta>` |

---

## Changelog

| Fecha | Versión | Cambios |
|-------|---------|---------|
| 2026-01-11 | 0.2 | Configuración inicial BETA con Cloudflare |

---

**Última actualización**: 2026-01-11
**Mantenedor**: DevOps Agent
**Entorno**: BETA (Staging)
