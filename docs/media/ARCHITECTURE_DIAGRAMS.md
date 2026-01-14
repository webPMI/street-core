# Diagramas de Arquitectura - Sistema de Media

Documentación visual del flujo y arquitectura del sistema de uploads.

---

## Arquitectura General

```
┌─────────────────────────────────────────────────────────────────┐
│                        FRONTEND (Flutter)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Profile    │  │    Posts     │  │Competitions  │          │
│  │   Module     │  │   Module     │  │   Module     │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                  │
│         └──────────────────┼──────────────────┘                  │
│                            │                                     │
│                    ┌───────▼───────┐                             │
│                    │ Upload Widgets│                             │
│                    │  - Avatar     │                             │
│                    │  - FileUpload │                             │
│                    │  - MediaSection│                            │
│                    └───────┬───────┘                             │
│                            │                                     │
│                    ┌───────▼────────┐                            │
│                    │ MediaValidator │                            │
│                    │  - Size check  │                            │
│                    │  - Type check  │                            │
│                    │  - Dimensions  │                            │
│                    └───────┬────────┘                            │
│                            │                                     │
│                    ┌───────▼────────┐                            │
│                    │MediaUploadSvc  │                            │
│                    │ - uploadAvatar │                            │
│                    │ - uploadImage  │                            │
│                    │ - uploadMultiple│                           │
│                    └───────┬────────┘                            │
│                            │                                     │
│                    ┌───────▼────────┐                            │
│                    │ApiMediaService │                            │
│                    │ - HTTP client  │                            │
│                    │ - Multipart    │                            │
│                    │ - CSRF tokens  │                            │
│                    └───────┬────────┘                            │
└────────────────────────────┼────────────────────────────────────┘
                             │
                        HTTPS │ POST /api/v2/media/upload/*
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                       BACKEND (Go + Gin)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                     ┌───────────────┐                            │
│                     │  Middlewares  │                            │
│                     │ - JWT Auth    │                            │
│                     │ - CSRF Verify │                            │
│                     │ - Rate Limit  │                            │
│                     └───────┬───────┘                            │
│                             │                                    │
│                     ┌───────▼───────┐                            │
│                     │ Media Handler │                            │
│                     │ - Upload()    │                            │
│                     │ - UploadMultiple│                          │
│                     └───────┬───────┘                            │
│                             │                                    │
│                     ┌───────▼───────┐                            │
│                     │ Media Service │                            │
│                     │ - Validation  │                            │
│                     │ - Deduplication│                           │
│                     │ - Processing  │                            │
│                     └───────┬───────┘                            │
│                             │                                    │
│              ┌──────────────┼──────────────┐                     │
│              │              │              │                     │
│      ┌───────▼──────┐ ┌────▼────┐ ┌───────▼──────┐              │
│      │File Storage  │ │MongoDB  │ │ Processor    │              │
│      │- Save file   │ │- Metadata│ │- Thumbnails  │              │
│      │- Hash calc   │ │- Indexes │ │- Dimensions  │              │
│      │- Auto-resize │ │- Queries │ │- Async jobs  │              │
│      └──────────────┘ └─────────┘ └──────────────┘              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Flujo de Upload Simple

```
Usuario                Widget            Validator         Service          Backend
  │                      │                   │                │                │
  │  1. Selecciona      │                   │                │                │
  │     archivo          │                   │                │                │
  ├─────────────────────>│                   │                │                │
  │                      │                   │                │                │
  │                      │  2. Valida tamaño │                │                │
  │                      ├──────────────────>│                │                │
  │                      │                   │                │                │
  │                      │  3. Valida tipo   │                │                │
  │                      │<──────────────────┤                │                │
  │                      │                   │                │                │
  │                      │  4. Upload        │                │                │
  │                      ├──────────────────────────────────>│                │
  │                      │                   │                │                │
  │                      │                   │                │  5. POST req  │
  │                      │                   │                ├───────────────>│
  │                      │                   │                │                │
  │                      │                   │                │  6. Validación│
  │                      │                   │                │    server     │
  │                      │                   │                │                │
  │                      │                   │                │  7. Guarda    │
  │                      │                   │                │    archivo    │
  │                      │                   │                │                │
  │                      │                   │                │  8. Crea DB   │
  │                      │                   │                │    record     │
  │                      │                   │                │                │
  │                      │                   │                │  9. Response  │
  │                      │                   │                │<───────────────┤
  │                      │                   │                │                │
  │                      │  10. Response     │                │                │
  │                      │<──────────────────────────────────┤                │
  │                      │                   │                │                │
  │  11. Muestra         │                   │                │                │
  │      preview         │                   │                │                │
  │<─────────────────────┤                   │                │                │
  │                      │                   │                │                │
  │                      │                   │                │  (Async)      │
  │                      │                   │                │  12. Process  │
  │                      │                   │                │      thumbnail│
  │                      │                   │                │                │
```

---

## Validación Multi-Capa

```
                        ┌──────────────────────┐
                        │   Archivo del        │
                        │   Usuario            │
                        └──────────┬───────────┘
                                   │
                        ┌──────────▼───────────┐
                        │  CAPA 1: Frontend    │
                        │  MediaValidator      │
                        ├──────────────────────┤
                        │ ✓ Tamaño archivo     │
                        │ ✓ Extensión          │
                        │ ✓ Dimensiones imagen │
                        │ ✓ MIME type (opt)    │
                        │ ✓ Cantidad archivos  │
                        └──────────┬───────────┘
                                   │
                                   │ PASS
                                   │
                        ┌──────────▼───────────┐
                        │  HTTP Request        │
                        │  + CSRF Token        │
                        │  + JWT Token         │
                        └──────────┬───────────┘
                                   │
                        ┌──────────▼───────────┐
                        │  CAPA 2: Middlewares │
                        ├──────────────────────┤
                        │ ✓ JWT válido         │
                        │ ✓ CSRF válido        │
                        │ ✓ Rate limit OK      │
                        └──────────┬───────────┘
                                   │
                                   │ PASS
                                   │
                        ┌──────────▼───────────┐
                        │  CAPA 3: Backend     │
                        │  ValidateFileUpload  │
                        ├──────────────────────┤
                        │ ✓ Magic bytes        │
                        │ ✓ MIME real          │
                        │ ✓ Extensión vs MIME  │
                        │ ✓ Tamaño             │
                        │ ✓ Dimensiones        │
                        │ ✓ Patterns maliciosos│
                        └──────────┬───────────┘
                                   │
                                   │ PASS
                                   │
                        ┌──────────▼───────────┐
                        │  CAPA 4: Business    │
                        │  Logic               │
                        ├──────────────────────┤
                        │ ✓ User ID válido     │
                        │ ✓ Límite archivos    │
                        │   (1000 max)         │
                        │ ✓ Hash duplicado     │
                        │ ✓ Ownership (delete) │
                        └──────────┬───────────┘
                                   │
                                   │ PASS
                                   │
                        ┌──────────▼───────────┐
                        │   ARCHIVO ACEPTADO   │
                        │   Guarda en disco    │
                        └──────────────────────┘
```

---

## Estructura de Almacenamiento

```
/uploads (raíz configurable)
│
├── /images (Flat - Legacy)
│   ├── userid1_uuid1.jpg
│   ├── userid2_uuid2.png
│   └── ...
│
├── /videos (Flat - Legacy)
│   ├── userid1_uuid3.mp4
│   └── ...
│
├── /avatars (Flat - Legacy)
│   ├── userid1_uuid4.jpg
│   └── ...
│
├── /thumbnails (Auto-generados)
│   ├── userid1_uuid1_thumb.jpg
│   ├── userid1_uuid3_thumb.jpg (video thumb - pendiente)
│   └── ...
│
├── /temp (Limpieza automática >24h)
│   ├── temp_file1.tmp
│   └── ...
│
├── /posts (Context-based)
│   ├── /images
│   │   ├── userid1_uuid5.jpg
│   │   └── ...
│   └── /videos
│       ├── userid1_uuid6.mp4
│       └── ...
│
├── /competitions (Context-based)
│   ├── /images
│   │   ├── userid2_uuid7.jpg  (banner)
│   │   ├── userid2_uuid8.png  (logo)
│   │   └── ...
│   └── /videos
│       └── ...
│
├── /clubs (Context-based)
│   ├── /images
│   └── /videos
│
├── /events (Context-based)
│   ├── /images
│   └── /videos
│
└── /profiles (Context-based)
    ├── /images
    └── /avatars
```

---

## Procesamiento de Imagen

```
┌─────────────────────────────────────────────────────────────┐
│                    UPLOAD EXITOSO                            │
└───────────────────────────┬─────────────────────────────────┘
                            │
                ┌───────────▼──────────┐
                │ Archivo guardado     │
                │ Status: PENDING      │
                └───────────┬──────────┘
                            │
                            │ Async Job
                            │
            ┌───────────────▼───────────────┐
            │   PROCESAMIENTO ASÍNCRONO     │
            └───────────────┬───────────────┘
                            │
                ┌───────────▼──────────┐
                │ 1. Abrir imagen      │
                │    (imaging library) │
                └───────────┬──────────┘
                            │
                ┌───────────▼──────────┐
                │ 2. Extraer           │
                │    - Width           │
                │    - Height          │
                │    - AspectRatio     │
                └───────────┬──────────┘
                            │
                ┌───────────▼──────────┐
                │ 3. ¿>4096x4096?      │
                └───────┬───────┬──────┘
                        │       │
                    YES │       │ NO
                        │       │
            ┌───────────▼──┐    │
            │ Auto-resize  │    │
            │ Lanczos      │    │
            │ Quality 90%  │    │
            └───────────┬──┘    │
                        │       │
                        └───┬───┘
                            │
                ┌───────────▼──────────┐
                │ 4. Crear thumbnail   │
                │    - 400x400         │
                │    - JPEG Q85        │
                │    - Mantiene ratio  │
                └───────────┬──────────┘
                            │
                ┌───────────▼──────────┐
                │ 5. Guardar thumbnail │
                │    /thumbnails/      │
                │    *_thumb.jpg       │
                └───────────┬──────────┘
                            │
                ┌───────────▼──────────┐
                │ 6. Update DB         │
                │    - Status: READY   │
                │    - Width, Height   │
                │    - AspectRatio     │
                │    - ThumbnailURL    │
                └───────────┬──────────┘
                            │
                ┌───────────▼──────────┐
                │   PROCESAMIENTO      │
                │    COMPLETADO        │
                └──────────────────────┘
```

---

## Deduplicación por Hash

```
                    ┌────────────────┐
                    │ Nuevo Upload   │
                    └────────┬───────┘
                             │
                             │ Durante guardado
                             │
                    ┌────────▼────────┐
                    │ Calcular SHA256 │
                    │ (mientras copia)│
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Hash: abc123... │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Buscar en DB    │
                    │ por hash        │
                    └────┬─────┬──────┘
                         │     │
                   EXISTE│     │NO EXISTE
                         │     │
            ┌────────────▼──┐  │
            │ DUPLICADO!    │  │
            │               │  │
            │ 1. Borrar     │  │
            │    archivo    │  │
            │    físico     │  │
            │               │  │
            │ 2. Retornar   │  │
            │    registro   │  │
            │    existente  │  │
            │               │  │
            │ 3. Mismo URL  │  │
            └───────────────┘  │
                               │
                  ┌────────────▼────────┐
                  │ ÚNICO               │
                  │                     │
                  │ 1. Mantener archivo │
                  │                     │
                  │ 2. Crear registro   │
                  │    nuevo en DB      │
                  │                     │
                  │ 3. Nuevo URL        │
                  └─────────────────────┘
```

---

## Limpieza Automática

```
                ┌─────────────────────────┐
                │  Cron Job (cada 1 hora)│
                └───────────┬─────────────┘
                            │
                ┌───────────▼────────────┐
                │ Escanear archivos      │
                └───────────┬────────────┘
                            │
            ┌───────────────┼───────────────┐
            │                               │
    ┌───────▼────────┐           ┌─────────▼──────┐
    │ Archivos       │           │ Archivos Temp  │
    │ Huérfanos      │           │                │
    └───────┬────────┘           └─────────┬──────┘
            │                              │
    ┌───────▼────────┐           ┌─────────▼──────┐
    │ Criterios:     │           │ Criterios:     │
    │ • Sin postId   │           │ • En /temp/    │
    │ • >24 horas    │           │ • >24 horas    │
    │ • Status=ready │           │                │
    │ • Tipo≠avatar  │           │                │
    └───────┬────────┘           └─────────┬──────┘
            │                              │
    ┌───────▼────────┐           ┌─────────▼──────┐
    │ Eliminar:      │           │ Eliminar:      │
    │ • Archivo físico│           │ • Archivo .tmp │
    │ • Registro DB   │           │                │
    │ • Thumbnail     │           │                │
    └────────────────┘           └────────────────┘
```

---

## Rate Limiting

```
                    ┌─────────────────┐
                    │  Request Upload │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Extract User ID │
                    │ (from JWT)      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Check Redis/    │
                    │ Memory Counter  │
                    │ Key: upload:{id}│
                    └────┬─────┬──────┘
                         │     │
                  <10    │     │ ≥10
                         │     │
            ┌────────────▼──┐  │
            │ ALLOW         │  │
            │               │  │
            │ 1. Increment  │  │
            │    counter    │  │
            │               │  │
            │ 2. Set TTL    │  │
            │    60 seconds │  │
            │               │  │
            │ 3. Process    │  │
            │    upload     │  │
            └───────────────┘  │
                               │
                  ┌────────────▼────────┐
                  │ REJECT              │
                  │                     │
                  │ 1. Return 429       │
                  │                     │
                  │ 2. Retry-After: 60  │
                  │                     │
                  │ 3. Error message    │
                  └─────────────────────┘
```

---

## CSRF Protection Flow

```
    Cliente                Backend
      │                      │
      │  1. GET /csrf-token  │
      ├─────────────────────>│
      │                      │
      │                      │  2. Genera token
      │                      │     (32 bytes random)
      │                      │
      │                      │  3. Guarda en MongoDB
      │                      │     con TTL
      │                      │
      │  4. Response         │
      │     {csrf_token}     │
      │<─────────────────────┤
      │                      │
      │  5. POST /upload     │
      │     X-CSRF-Token:    │
      │     {token}          │
      ├─────────────────────>│
      │                      │
      │                      │  6. Valida en DB
      │                      │     • Existe?
      │                      │     • No expirado?
      │                      │
      │                      ├─ SI: Procesa upload
      │                      │
      │                      └─ NO: 403 Forbidden
      │                      │
      │  7. Response         │
      │<─────────────────────┤
      │                      │
```

---

## Módulos y Dependencias

```
                    ┌────────────────────┐
                    │   Features Layer   │
                    ├────────────────────┤
                    │ • Profile          │
                    │ • Posts            │
                    │ • Competitions     │
                    │ • Stories          │
                    └─────────┬──────────┘
                              │
                              │ usa
                              │
                    ┌─────────▼──────────┐
                    │   Core Media Layer │
                    ├────────────────────┤
                    │ • MediaUploadSvc   │
                    │ • MediaValidator   │
                    │ • Widgets          │
                    └─────────┬──────────┘
                              │
                              │ usa
                              │
                    ┌─────────▼──────────┐
                    │  API Services Layer│
                    ├────────────────────┤
                    │ • ApiMediaService  │
                    │ • HTTP Client      │
                    │ • Interceptors     │
                    └─────────┬──────────┘
                              │
                              │ HTTP
                              │
                    ┌─────────▼──────────┐
                    │   Backend (Go)     │
                    ├────────────────────┤
                    │ features/media/    │
                    │ • Handler          │
                    │ • Service          │
                    │ • Repository       │
                    │ • Processor        │
                    │                    │
                    │ pkg/media/         │
                    │ • Upload utils     │
                    │ • Validation       │
                    └────────────────────┘
```

---

## Estado de Archivos (State Machine)

```
                    ┌─────────────┐
                    │   UPLOAD    │
                    └──────┬──────┘
                           │
                           │ Create
                           │
                    ┌──────▼──────┐
              ┌─────│   PENDING   │
              │     └──────┬──────┘
              │            │
              │            │ Start Processing
              │            │
              │     ┌──────▼──────┐
              │     │ PROCESSING  │
              │     └──────┬──────┘
              │            │
              │            │ Success
              │            │
              │     ┌──────▼──────┐
              │     │    READY    │────┐
              │     └─────────────┘    │
              │                        │
              │ Error                  │ User can access
              │                        │
       ┌──────▼──────┐                 │
       │   FAILED    │                 │
       └─────────────┘                 │
                                       │
                                       │ Delete
                                       │
                                ┌──────▼──────┐
                                │   DELETED   │
                                └─────────────┘

Estados:
• PENDING: Archivo guardado, esperando procesamiento
• PROCESSING: Generando thumbnails, extrayendo metadata
• READY: Disponible para usar
• FAILED: Error en procesamiento (no bloqueante)
• DELETED: Eliminado por usuario o cleanup
```

---

**Fin de Diagramas**

Estos diagramas complementan la documentación escrita y facilitan la comprensión visual del sistema.
