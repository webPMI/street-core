# StreetCore BETA - Quick Start Guide

## 5 Minutos para Levantar el Entorno

### Requisitos
- Docker 20.10+ instalado y corriendo
- 4 GB RAM disponibles
- 10 GB espacio en disco

---

## Paso 1: Configurar Variables

```bash
# Copiar archivo de configuración
cp .env.beta .env

# Editar dominios (opcional para local)
nano .env.beta
```

**Para desarrollo local**: Los valores por defecto funcionan sin cambios.

---

## Paso 2: Iniciar Servicios

### Linux/macOS
```bash
chmod +x start-beta.sh
./start-beta.sh
```

### Windows (PowerShell como Administrador)
```powershell
.\start-beta.ps1
```

### Usando Make (Linux/macOS)
```bash
make start
```

**Tiempo estimado**: 5-10 minutos (primera vez, descarga imágenes)

---

## Paso 3: Acceder a la Aplicación

Una vez que los servicios estén **healthy**:

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Frontend** | http://localhost:80 | - |
| **Backend API** | http://localhost:3000 | - |
| **Admin Login** | http://localhost:80/admin | `admin@fitriders.com` / `Aa-1234!` |

**Health Checks**:
```bash
curl http://localhost:3000/health  # Backend
curl http://localhost:80/health     # Frontend
```

---

## Comandos Útiles

### Ver Logs
```bash
# Todos los servicios
docker-compose logs -f

# Solo backend
docker-compose logs -f backend

# Solo frontend
docker-compose logs -f frontend
```

### Detener Servicios
```bash
# Linux/macOS
./stop-beta.sh

# Windows
.\stop-beta.ps1

# Make
make stop
```

### Resetear Datos (ADVERTENCIA: Borra todo)
```bash
# Linux/macOS
./reset-beta.sh

# Windows
.\reset-beta.ps1

# Make
make reset
```

### Estado de Servicios
```bash
docker-compose ps

# O con Make
make status
```

---

## Desarrollo Local

### Con Hot Reload (Go + Flutter)

```bash
# Iniciar modo desarrollo
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# O con Make
make dev
```

**Backend**: Air detecta cambios y recompila automáticamente
**Frontend**: Flutter hot reload habilitado

---

## Troubleshooting Rápido

### Puertos Ocupados

**Cambiar puertos** en `docker-compose.yml`:
```yaml
services:
  backend:
    ports:
      - "3001:3000"  # Cambiar 3000 a 3001

  frontend:
    ports:
      - "8080:80"    # Cambiar 80 a 8080
```

### Servicios No Inician

```bash
# Ver logs de error
docker-compose logs

# Limpiar y reintentar
docker-compose down
docker system prune -f
./start-beta.sh
```

### MongoDB No Conecta

```bash
# Resetear completamente
./reset-beta.sh
```

---

## Comandos Make Disponibles

```bash
make help           # Ver todos los comandos
make start          # Iniciar servicios
make stop           # Detener servicios
make restart        # Reiniciar servicios
make logs           # Ver logs
make status         # Estado de servicios
make health         # Verificar salud de servicios
make backup         # Backup completo
make clean          # Limpiar contenedores parados
make shell-backend  # Acceder a shell del backend
make shell-mongodb  # Acceder a MongoDB shell
```

---

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                   Docker Network                     │
│              (172.20.0.0/16)                        │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐│
│  │   Frontend   │  │   Backend    │  │  MongoDB  ││
│  │ Flutter Web  │  │    Go/Gin    │  │   7.0     ││
│  │   (Nginx)    │  │              │  │           ││
│  │   Port 80    │  │  Port 3000   │  │ Port 27017││
│  └──────────────┘  └──────────────┘  └───────────┘│
│         │                 │                  │      │
│         └─────────────────┴──────────────────┘     │
│                                                      │
└─────────────────────────────────────────────────────┘
         │                 │                  │
         │                 │                  │
    Volumes:           Volumes:          Volumes:
    - None        - backend_uploads   - mongodb_data
                  - backend_logs      - mongodb_config
```

---

## Siguientes Pasos

1. **Leer documentación completa**: `BETA-DEPLOYMENT.md`
2. **Configurar Cloudflare**: Para producción (DNS, SSL, WAF)
3. **Backups automáticos**: Configurar cron jobs
4. **Monitoreo**: Configurar Prometheus + Grafana (opcional)

---

## Recursos

| Archivo | Descripción |
|---------|-------------|
| `docker-compose.yml` | Configuración principal |
| `BETA-DEPLOYMENT.md` | Guía completa de despliegue |
| `.env.beta` | Variables de entorno |
| `Makefile` | Comandos rápidos |

---

**Última actualización**: 2026-01-11
**Entorno**: BETA (Staging)
**Versión**: 0.2
