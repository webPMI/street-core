# Sistema de Upload de Archivos - Guía de Referencia

**Versión**: 1.0
**Última actualización**: 2026-01-05
**Propósito**: Documentar todos los puntos de upload, límites y almacenamiento del sistema

---

## Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Tipos de Archivos y Límites](#tipos-de-archivos-y-límites)
3. [Puntos de Upload por Módulo](#puntos-de-upload-por-módulo)
4. [Endpoints Backend](#endpoints-backend)
5. [Almacenamiento de Archivos](#almacenamiento-de-archivos)
6. [Capas de Seguridad](#capas-de-seguridad)
7. [Flujo de Datos](#flujo-de-datos)
8. [Configuración](#configuración)

---

## Resumen Ejecutivo

El sistema de media de StreetCore maneja uploads de imágenes, videos y avatares a través de múltiples módulos. Incluye validación multi-capa, procesamiento automático de imágenes, y almacenamiento organizado por contexto.

**Estadísticas del Sistema**:
- **Endpoints Backend**: 10 endpoints
- **Puntos de Upload Frontend**: 4 módulos principales
- **Tipos de Archivo**: Imágenes (5 formatos), Videos (5 formatos)
- **Límite Total por Usuario**: 1000 archivos
- **Rate Limit**: 10 uploads por minuto
- **Almacenamiento**: Organizado por contexto (competitions, posts, clubs, events, profiles)

---

## Tipos de Archivos y Límites

### Imágenes

**Formatos Permitidos**:
- JPEG (`.jpg`, `.jpeg`)
- PNG (`.png`)
- GIF (`.gif`)
- WebP (`.webp`)

**Límites**:
- **Avatar**: Máximo 5MB
- **Imagen General**: Máximo 10MB
- **Dimensiones Mínimas**: 50x50 píxeles
- **Dimensiones Máximas**: 8192x8192 píxeles (8K)
- **Auto-redimensionamiento**: Si la imagen supera 4096x4096, se redimensiona automáticamente

**MIME Types**:
- `image/jpeg`
- `image/png`
- `image/gif`
- `image/webp`

### Videos

**Formatos Permitidos**:
- MP4 (`.mp4`)
- MPEG (`.mpeg`, `.mpg`)
- QuickTime (`.mov`)
- AVI (`.avi`)
- WebM (`.webm`)

**Límites**:
- **Tamaño Máximo**: 500MB
- **Duración**: Sin límite específico
- **Procesamiento**: Pendiente (FFmpeg no implementado)

**MIME Types**:
- `video/mp4`
- `video/mpeg`
- `video/quicktime`
- `video/x-msvideo`
- `video/webm`

### Uploads Múltiples

**Límites**:
- **Máximo de Archivos**: 10 archivos por upload
- **Tamaño Total**: Sin límite específico (validado individualmente)
- **Tipos Mixtos**: Soportado (imágenes + videos en el mismo upload)

---

## Puntos de Upload por Módulo

### 1. Módulo de Perfil (Profile)

#### Avatar de Usuario
- **Ubicación**: Página de edición de perfil
- **Widget**: `AvatarUploadWidget`
- **Tipo**: Imagen
- **Límite**: 5MB
- **Endpoint**: `POST /api/v2/media/upload/avatar`
- **Almacenamiento**: `uploads/avatars/` o `uploads/profiles/avatars/`
- **Características**:
  - Selección desde cámara (solo móvil)
  - Selección desde galería
  - Drag & drop (web)
  - Preview circular
  - Actualización inmediata del perfil
  - Invalidación de caché automática

#### Imagen de Perfil
- **Ubicación**: Servicio de perfil
- **Método**: `uploadProfilePicture()`
- **Tipo**: Imagen
- **Límite**: 5MB
- **Endpoint**: `POST /api/v2/media/upload/avatar`
- **Almacenamiento**: `uploads/avatars/`
- **Características**:
  - Compatibilidad web (bytes) y móvil (File)
  - Invalidación de caché de perfil y posts

### 2. Módulo de Posts

#### Multimedia de Post
- **Ubicación**: Página de creación de post
- **Widget**: `MediaUploadSection`
- **Tipo**: Imágenes y videos mixtos
- **Límite**: 10MB por imagen, 500MB por video
- **Cantidad**: Máximo 10 archivos
- **Endpoint**: `POST /api/v2/media/upload/multiple`
- **Almacenamiento**: `uploads/posts/images/` o `uploads/posts/videos/`
- **Características**:
  - Detección automática de tipo (imagen/video)
  - Grid de preview con tamaños
  - Badge de cover en primera imagen
  - Selección desde cámara (móvil) o galería
  - Validación de al menos 1 archivo
  - Gestión vía `CreatePostCubit`

### 3. Módulo de Historias (Stories)

#### Imagen/Video de Historia
- **Ubicación**: Servicio de historias
- **Método**: `createStory()`
- **Tipo**: Imagen o video individual
- **Límite**: 10MB imagen, 500MB video
- **Endpoint**: `POST /api/v2/media/upload/image` o `/video`
- **Almacenamiento**: `uploads/images/` o `uploads/videos/`
- **Características**:
  - Auto-detección de tipo por extensión
  - Upload único por historia
  - Expiración a las 24 horas
  - Sin preview previo

### 4. Módulo de Competiciones

#### Imágenes de Competición
- **Ubicación**: Cubit de competiciones
- **Método**: `_processImageFields()`
- **Tipo**: Múltiples imágenes (banner, logo, etc.)
- **Límite**: 10MB por imagen
- **Endpoint**: `POST /api/v2/media/upload/image`
- **Almacenamiento**: `uploads/competitions/images/`
- **Características**:
  - Upload automático durante create/update
  - Soporte web (bytes) y móvil (File)
  - Mapeo de campos de imagen
  - Cache-busting automático
  - Detección de extensión desde bytes

---

## Endpoints Backend

### Endpoints de Upload

#### 1. Upload Genérico
```
POST /api/v2/media/upload
```
- **Propósito**: Upload de archivo individual (cualquier tipo)
- **Parámetros**:
  - `file`: Archivo (multipart/form-data)
  - `fileType`: image | video | avatar
- **Autenticación**: Requerida (JWT)
- **CSRF**: Requerida
- **Rate Limit**: 10 por minuto
- **Respuesta**: Metadata del archivo (id, url, thumbnailUrl, tamaño, etc.)

#### 2. Upload de Avatar
```
POST /api/v2/media/upload/avatar
```
- **Propósito**: Endpoint especializado para avatares
- **Parámetros**: `file` (max 5MB)
- **Validación**: Solo imágenes
- **Thumbnail**: Generado automáticamente (400x400)
- **Autenticación**: Requerida
- **CSRF**: Requerida
- **Rate Limit**: 10 por minuto

#### 3. Upload de Imagen
```
POST /api/v2/media/upload/image
```
- **Propósito**: Upload de imagen general
- **Parámetros**: `file` (max 10MB)
- **Validación**: Solo imágenes
- **Auto-resize**: Si > 4096x4096
- **Thumbnail**: Generado automáticamente
- **Autenticación**: Requerida
- **CSRF**: Requerida
- **Rate Limit**: 10 por minuto

#### 4. Upload de Video
```
POST /api/v2/media/upload/video
```
- **Propósito**: Upload de video
- **Parámetros**: `file` (max 500MB)
- **Validación**: Solo videos
- **Procesamiento**: Pendiente (FFmpeg)
- **Autenticación**: Requerida
- **CSRF**: Requerida
- **Rate Limit**: 10 por minuto

#### 5. Upload Múltiple
```
POST /api/v2/media/upload/multiple
```
- **Propósito**: Upload de hasta 10 archivos simultáneamente
- **Parámetros**: `files[]` (max 10 archivos)
- **Validación**: Mixta (imágenes + videos)
- **Respuesta**: Array de resultados + errores individuales
- **Autenticación**: Requerida
- **CSRF**: Requerida
- **Rate Limit**: 10 por minuto

### Endpoints de Gestión

#### 6. Listar Archivos del Usuario
```
GET /api/v2/media/me?page=1&limit=20
```
- **Propósito**: Obtener archivos del usuario autenticado
- **Parámetros**: Paginación (page, limit)
- **Respuesta**: Lista paginada con metadata
- **Autenticación**: Requerida

#### 7. Obtener Archivo por ID
```
GET /api/v2/media/:id
```
- **Propósito**: Obtener metadata de un archivo específico
- **Parámetros**: `id` (ObjectID)
- **Autenticación**: Requerida

#### 8. Eliminar Archivo
```
DELETE /api/v2/media/:id
```
- **Propósito**: Eliminar archivo físico y registro
- **Validación**: Solo el propietario puede eliminar
- **Seguridad**: Validación de path (no permite borrar fuera de uploads/)
- **Autenticación**: Requerida
- **CSRF**: Requerida

#### 9. Asociar Media a Post
```
POST /api/v2/media/associate
```
- **Propósito**: Vincular archivos a un post
- **Parámetros**:
  - `mediaIds`: Array de IDs (max 10)
  - `postId`: ID del post
- **Validación**: Ownership del post
- **Autenticación**: Requerida
- **CSRF**: Requerida

#### 10. Obtener Media de Post
```
GET /api/v2/media/post/:postId
```
- **Propósito**: Obtener todos los archivos de un post
- **Parámetros**: `postId`
- **Estado**: Implementación parcial
- **Autenticación**: Requerida

---

## Almacenamiento de Archivos

### Estructura de Directorios

```
uploads/
├── images/                    # Imágenes generales (legacy)
├── videos/                    # Videos generales (legacy)
├── avatars/                   # Avatares (legacy)
├── thumbnails/                # Thumbnails generados
├── temp/                      # Archivos temporales (<24h)
│
├── competitions/              # Contexto: Competiciones
│   ├── images/
│   ├── videos/
│   └── avatars/
│
├── posts/                     # Contexto: Posts
│   ├── images/
│   └── videos/
│
├── clubs/                     # Contexto: Clubs
│   ├── images/
│   └── videos/
│
├── events/                    # Contexto: Eventos
│   ├── images/
│   └── videos/
│
└── profiles/                  # Contexto: Perfiles
    ├── images/
    └── avatars/
```

### Convenciones de Nombres

**Formato**: `{userId}_{uuid}.{extension}`

**Ejemplo**: `507f1f77bcf86cd799439011_a3f2b9c1-4d5e-6789-0abc-def123456789.jpg`

**Características**:
- **userId**: Identifica al propietario
- **uuid**: Garantiza unicidad
- **extension**: Preservada del archivo original
- **Hash SHA256**: Calculado para deduplicación

### URLs Públicas

**Formato**: `/uploads/{context}/{type}/{filename}`

**Ejemplos**:
- Avatar general: `/uploads/avatars/507f1f77_uuid.jpg`
- Post image: `/uploads/posts/images/507f1f77_uuid.jpg`
- Competition banner: `/uploads/competitions/images/507f1f77_uuid.jpg`
- Thumbnail: `/uploads/thumbnails/507f1f77_uuid_thumb.jpg`

### Contextos de Almacenamiento

| Contexto | Descripción | Ruta Base |
|----------|-------------|-----------|
| `general` | Sin contexto específico (legacy) | `uploads/{type}/` |
| `competitions` | Archivos de competiciones | `uploads/competitions/{type}/` |
| `posts` | Archivos de posts | `uploads/posts/{type}/` |
| `clubs` | Archivos de clubs | `uploads/clubs/{type}/` |
| `events` | Archivos de eventos | `uploads/events/{type}/` |
| `profiles` | Archivos de perfiles | `uploads/profiles/{type}/` |

---

## Capas de Seguridad

### 1. Validación Frontend (Cliente)

**Validador**: `MediaValidator` (Dart)

**Validaciones**:
- Tamaño de archivo (5MB avatar, 10MB imagen, 500MB video)
- Extensión de archivo (lista blanca)
- Dimensiones de imagen (min 50x50, max 8192x8192)
- MIME type (si disponible)
- Cantidad de archivos (max 10 en múltiples)
- Tamaño total en uploads múltiples

**Beneficios**:
- Feedback inmediato al usuario
- Reducción de tráfico de red
- Mejor UX con mensajes localizados

### 2. Validación Backend (Servidor)

**Validador**: `ValidateFileUpload()` (Go)

**Validaciones**:
- **Magic Bytes**: Detección real del tipo de archivo (primeros 512 bytes)
- **MIME Type**: Validación contra tipos permitidos
- **Extensión vs MIME**: Verificación de coincidencia
- **Tamaño**: Límites por tipo de archivo
- **Dimensiones**: Mínimo 50x50 para imágenes
- **Patterns Maliciosos**: Detección de ejecutables, scripts, etc.

**Patterns Detectados**:
- Ejecutables Windows (`MZ`)
- Ejecutables Linux (`\x7fELF`)
- Scripts shell (`#!/`)
- Código PHP (`<?php`)
- JavaScript (`<script`)
- Código evaluado (`eval(`)

### 3. Autenticación y Autorización

**JWT Authentication**:
- Todas las rutas requieren token válido
- Token extraído del header `Authorization: Bearer {token}`
- User ID extraído del contexto JWT

**CSRF Protection**:
- Validación de token CSRF en operaciones POST/DELETE
- Token obtenido de: `GET /api/v2/csrf-token`
- Token enviado en header: `X-CSRF-Token`
- Almacenamiento: MongoDB con TTL automático
- Fallback: In-memory si MongoDB no disponible

**Ownership Validation**:
- Solo el propietario puede eliminar archivos
- Validación de ownership en asociación a posts
- User ID verificado contra JWT context

### 4. Rate Limiting

**Configuración**:
- **Límite**: 10 requests por minuto por usuario
- **Ventana**: 1 minuto
- **Respuesta**: 429 Too Many Requests
- **Header**: `Retry-After` con segundos de espera

**Aplica a**:
- Todos los endpoints de upload (`/upload/*`)
- Por usuario (basado en JWT)

### 5. Límites de Negocio

**Por Usuario**:
- **Máximo de archivos**: 1000 archivos totales
- Validado antes de cada upload
- Incluye todos los tipos de archivos

**Deduplicación**:
- Hash SHA256 calculado durante upload
- Verificación de hash existente en base de datos
- Si existe: archivo físico eliminado, registro reutilizado
- Ahorra espacio de almacenamiento

### 6. Limpieza Automática

**Archivos Huérfanos**:
- **Condiciones**: Sin `postId`, >24 horas, status=ready, tipo≠avatar
- **Frecuencia**: Job cada 1 hora
- **Acción**: Elimina archivo físico + registro DB

**Archivos Temporales**:
- **Ubicación**: `uploads/temp/`
- **Retención**: 24 horas
- **Frecuencia**: Job cada 1 hora
- **Acción**: Elimina archivos >24h

---

## Flujo de Datos

### Flujo de Upload Simple

```
1. Usuario selecciona archivo
   └─> ImagePicker / FileUploadWidget

2. Validación cliente
   └─> MediaValidator
       ├─ Tamaño OK?
       ├─ Extensión OK?
       └─ Dimensiones OK?

3. Upload HTTP
   └─> MediaUploadService.uploadImage()
       └─> ApiMediaService.uploadFile()
           ├─ Multipart form-data
           ├─ CSRF token
           ├─ Authorization header
           └─ Timeout: 5 minutos

4. Backend recibe
   └─> mediaHandler.Upload()
       ├─ Extrae form data
       ├─ Valida JWT
       ├─ Valida CSRF
       └─> Rate limit check

5. Validación servidor
   └─> ValidateFileUpload()
       ├─ Magic bytes
       ├─ MIME type
       ├─ Extensión
       ├─ Tamaño
       └─ Dimensiones

6. Guardar archivo
   └─> SaveUploadedFileWithContext()
       ├─ Genera nombre único
       ├─ Calcula SHA256 hash
       ├─ Verifica duplicado
       ├─ Guarda en disco
       └─ Auto-resize si >4096x4096

7. Crear registro DB
   └─> repository.Create()
       ├─ MediaFile document
       ├─ Status: pending
       └─ Metadata

8. Procesamiento asíncrono
   └─> processFileAsync()
       ├─ Extrae dimensiones
       ├─ Genera thumbnail
       ├─ Actualiza status: ready
       └─ Guarda metadata

9. Respuesta cliente
   └─> MediaUploadResponse
       ├─ id
       ├─ publicUrl
       ├─ thumbnailUrl
       ├─ width, height
       └─ fileSize

10. UI actualización
    └─> Muestra preview
        └─> Invalida cache si necesario
```

### Flujo de Upload Múltiple

```
1. Usuario selecciona 10 archivos
   └─> MediaUploadSection

2. Validación por archivo
   └─> MediaValidator.validateMultipleFiles()
       ├─ Detecta tipo (imagen/video) por extensión
       ├─ Valida individualmente
       └─ Valida tamaño total

3. Upload concurrente
   └─> ApiMediaService.uploadMultipleXFiles()
       ├─ 10 requests HTTP simultáneos
       ├─ Cada uno con timeout propio
       └─ Fieldname: 'files'

4. Backend procesa
   └─> mediaHandler.UploadMultiple()
       ├─> Loop: service.UploadFile() x10
       ├─ Tracking: success/failed
       └─ Continúa aunque algunos fallen

5. Respuesta agregada
   └─> {
         files: [MediaUploadResponse[]],
         success: 8,
         failed: 2,
         errors: [{fileName, error}]
       }

6. Cliente procesa
   └─> PostService.createPost()
       ├─ URLs de archivos exitosos
       ├─ Muestra errores si existen
       └─ Crea post con media
```

---

## Configuración

### Variables de Entorno

```bash
# Directorio base de uploads (opcional)
UPLOAD_DIR=./uploads

# Límites de tamaño (configurado en código)
# No requieren variables de entorno
```

### Configuración Backend

**Archivo**: `backend/config/media_config.go`

**Parámetros Configurables**:
- `MaxImageSize`: 10MB (10 * 1024 * 1024 bytes)
- `MaxVideoSize`: 500MB (500 * 1024 * 1024 bytes)
- `MaxAvatarSize`: 5MB (5 * 1024 * 1024 bytes)
- `ThumbnailWidth`: 400px
- `ThumbnailHeight`: 400px
- `MaxFilesPerUpload`: 10 archivos
- `EnableVirusScan`: false (requiere ClamAV)
- `EnableMagicByteCheck`: true

**Directorios**:
- Creados automáticamente al inicio
- Permisos: 0755

### Configuración Frontend

**Archivo**: `street_core/lib/core/media/validators/media_validator.dart`

**Constantes**:
- `maxAvatarSize`: 5MB
- `maxImageSize`: 10MB
- `maxVideoSize`: 500MB
- `minImageWidth`: 50px
- `minImageHeight`: 50px
- `maxImageWidth`: 8192px
- `maxImageHeight`: 8192px

**Modificar**: Editar constantes en el archivo

### Timeouts de Red

**Archivo**: `street_core/lib/core/services/api_media_service.dart`

**Timeouts**:
- Upload individual: 5 minutos (300,000ms)
- Upload múltiple: 10 minutos (600,000ms)
- Download: 30 segundos (30,000ms)

---

## Notas Importantes para Desarrolladores

### ⚠️ Advertencias

1. **No modificar límites sin alinear frontend/backend**: Cambiar límites requiere actualizar ambos lados
2. **CSRF tokens son obligatorios**: Todos los uploads POST requieren token CSRF válido
3. **Rate limits son por usuario**: 10 uploads/minuto compartidos entre todos los endpoints
4. **Videos no se procesan**: FFmpeg no está implementado, duración siempre es 0
5. **Auto-resize es destructivo**: Imágenes >4096x4096 se redimensionan permanentemente

### ✅ Buenas Prácticas

1. **Usar MediaUploadService**: No llamar ApiMediaService directamente
2. **Validar antes de upload**: Siempre usar MediaValidator en frontend
3. **Manejar errores individualmente**: En uploads múltiples, algunos pueden fallar
4. **Invalidar cache**: Después de uploads de avatar/profile
5. **Usar contextos**: Preferir contextos (posts, competitions) sobre almacenamiento plano
6. **No almacenar URLs**: URLs pueden cambiar, usar IDs de media

### 🔧 Troubleshooting

**Error: "CSRF token missing"**
- Solución: Obtener token de `/api/v2/csrf-token` antes de upload

**Error: "File too large"**
- Frontend: Revisar MediaValidator límites
- Backend: Revisar config/media_config.go límites

**Error: "Invalid file type"**
- Verificar extensión está en lista permitida
- Verificar MIME type coincide con extensión

**Upload lento**
- Revisar tamaño de archivo (videos grandes toman tiempo)
- Verificar conexión de red
- Considerar reducir resolución antes de upload

**Archivos no se eliminan**
- Verificar ownership (solo propietario puede eliminar)
- Archivos con postId no se limpian automáticamente
- Avatares nunca se limpian automáticamente

---

## Próximos Pasos / Roadmap

### Pendiente de Implementación

1. **Procesamiento de Video**:
   - Integrar FFmpeg
   - Extraer duración real
   - Generar thumbnails de videos
   - Validar codecs

2. **Virus Scanning**:
   - Instalar y configurar ClamAV
   - Activar `EnableVirusScan: true`
   - Implementar cuarentena de archivos infectados

4. **Optimizaciones**:
   - Conversión automática a WebP
   - Redis caching de metadata
   - CDN integration
   - Chunked uploads para archivos grandes
   - Upload resumable

5. **Mejoras de UX**:
   - Barra de progreso granular
   - Compresión de imágenes antes de upload
   - Editor de imágenes (crop, rotate, filters)
   - Galería de media del usuario

---

## Changelog

### v1.0 (2026-01-05)
- Documentación inicial completa
- Alineación de límites de video (500MB frontend/backend)
- CSRF protection activada en todas las rutas
- Rate limits documentados (10/minuto)
- Auto-detección de tipo en validación múltiple
- Corrección de bug en validateXFile (solo validaba imágenes)

---

**Fin del documento**

Para preguntas o aclaraciones, consultar:
- Código fuente: `/backend/features/media/`, `/street_core/lib/core/media/`
- Configuración: `/backend/config/media_config.go`
- Tests: (Pendiente de crear)
