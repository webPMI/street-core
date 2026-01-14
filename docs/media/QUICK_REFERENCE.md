# Media System - Referencia Rápida

**Para desarrolladores que necesitan integrar uploads rápidamente**

---

## Límites de Archivos

| Tipo | Tamaño Máximo | Formatos | Endpoint |
|------|---------------|----------|----------|
| Avatar | 5MB | jpg, png, gif, webp | `/media/upload/avatar` |
| Imagen | 10MB | jpg, png, gif, webp | `/media/upload/image` |
| Video | 500MB | mp4, mov, webm, avi, mpeg | `/media/upload/video` |
| Múltiple | 10 archivos | Mixto | `/media/upload/multiple` |

---

## Frontend: Cómo Subir Archivos

### 1. Avatar Simple
```dart
// Obtener servicio
final uploadService = getIt<MediaUploadService>();

// Seleccionar archivo
final file = await uploadService.pickImage(fromCamera: false);

// Subir
final response = await uploadService.uploadAvatar(file);
print(response.url); // /uploads/avatars/userid_uuid.jpg
```

### 2. Imagen Individual
```dart
final response = await uploadService.uploadImage(file);
```

### 3. Múltiples Archivos
```dart
final picker = ImagePicker();
final List<XFile> files = await picker.pickMultiImage();

final responses = await uploadService.uploadMultipleXFile(files);
// responses: List<MediaUploadResponse>
```

### 4. Usando Widget
```dart
FileUploadWidget(
  maxFiles: 5,
  maxSizeBytes: 10 * 1024 * 1024, // 10MB
  allowedExtensions: ['.jpg', '.png'],
  onFilesChanged: (files) {
    // files: List<File>
  },
)
```

---

## Backend: Endpoints

### Obtener Token CSRF (Primero)
```bash
GET /api/v2/csrf-token
Authorization: Bearer {jwt_token}

Response:
{
  "status": "success",
  "csrf_token": "abc123...",
  "expires_at": 1704470400
}
```

### Upload Avatar
```bash
POST /api/v2/media/upload/avatar
Authorization: Bearer {jwt_token}
X-CSRF-Token: {csrf_token}
Content-Type: multipart/form-data

Form Data:
- file: (binary)

Response:
{
  "status": "success",
  "data": {
    "id": "507f1f77bcf86cd799439011",
    "publicUrl": "/uploads/avatars/userid_uuid.jpg",
    "thumbnailUrl": "/uploads/thumbnails/userid_uuid_thumb.jpg",
    "fileSize": 245678,
    "width": 800,
    "height": 600
  }
}
```

### Upload Múltiple
```bash
POST /api/v2/media/upload/multiple
Authorization: Bearer {jwt_token}
X-CSRF-Token: {csrf_token}
Content-Type: multipart/form-data

Form Data:
- files: (binary)
- files: (binary)
- ...

Response:
{
  "status": "success",
  "data": {
    "files": [...],
    "success": 8,
    "failed": 2,
    "errors": [
      {"fileName": "big.jpg", "error": "file too large"}
    ]
  }
}
```

### Obtener Media de un Post
```bash
GET /api/v2/media/post/:postId
Authorization: Bearer {jwt_token}

Response:
{
  "status": "success",
  "data": [
    {
      "id": "507f1f77bcf86cd799439011",
      "publicUrl": "/uploads/posts/images/userid_uuid.jpg",
      "thumbnailUrl": "/uploads/thumbnails/userid_uuid_thumb.jpg",
      "fileType": "image",
      "mimeType": "image/jpeg",
      "fileSize": 245678,
      "width": 1920,
      "height": 1080,
      "status": "ready"
    }
  ],
  "count": 1,
  "post_id": "507f1f77bcf86cd799439099"
}
```

---

## Validación

### Validar Antes de Upload
```dart
// Avatar
final validation = MediaValidator.validateAvatar(file);

// Imagen
final validation = MediaValidator.validateImage(file);

// XFile (cross-platform)
final validation = await MediaValidator.validateXFile(xfile);

// Múltiples
final validation = await MediaValidator.validateMultipleFiles(xfiles);

if (!validation.isValid) {
  print(validation.errorMessage);
  // "File too large (max 10MB)"
}
```

---

## Almacenamiento

### Estructura
```
uploads/
├── avatars/          # Avatares
├── images/           # Imágenes generales
├── videos/           # Videos generales
├── thumbnails/       # Thumbnails auto-generados
├── posts/images/     # Imágenes de posts
├── posts/videos/     # Videos de posts
└── competitions/     # Archivos de competiciones
```

### Nombre de Archivo
Formato: `{userId}_{uuid}.{ext}`

Ejemplo: `507f1f77bcf86cd799439011_a3f2b9c1-4d5e-6789.jpg`

---

## Seguridad

### Checklist de Upload
- [ ] Token JWT válido
- [ ] Token CSRF obtenido y enviado
- [ ] Archivo validado en frontend
- [ ] Tamaño dentro de límites
- [ ] Extensión permitida
- [ ] Rate limit respetado (10/minuto)

### Errores Comunes

**403 Forbidden - CSRF token missing**
→ Obtener token de `/csrf-token` y enviar en header `X-CSRF-Token`

**429 Too Many Requests**
→ Esperar 60 segundos (10 uploads/minuto)

**400 Bad Request - File too large**
→ Reducir tamaño o cambiar límites en config

**400 Bad Request - Invalid file type**
→ Verificar extensión permitida

---

## Configuración Rápida

### Cambiar Límites Backend
```go
// backend/config/media_config.go
MaxImageSize:  10 * 1024 * 1024,   // 10MB
MaxVideoSize:  500 * 1024 * 1024,  // 500MB
MaxAvatarSize: 5 * 1024 * 1024,    // 5MB
```

### Cambiar Límites Frontend
```dart
// lib/core/media/validators/media_validator.dart
static const int maxAvatarSize = 5 * 1024 * 1024;  // 5MB
static const int maxImageSize = 10 * 1024 * 1024;  // 10MB
static const int maxVideoSize = 500 * 1024 * 1024; // 500MB
```

### Cambiar Rate Limit
```go
// backend/models/rate_limit_model.go
UploadRateLimitConfig = RateLimitConfig{
    Name:   "upload",
    Rate:   10,                    // Requests
    Window: 1 * time.Minute,       // Por minuto
}
```

---

## Integración por Módulo

### Profile (Avatar)
```dart
// Usar AvatarUploadWidget
AvatarUploadWidget(
  currentAvatarUrl: user.avatarUrl,
  onAvatarSelected: (file) async {
    final response = await uploadService.uploadAvatar(file);
    await profileService.updateProfile(avatarUrl: response.url);
  },
)
```

### Posts (Múltiples Imágenes)
```dart
// Usar MediaUploadSection
MediaUploadSection(
  onMediaChanged: (files) {
    createPostCubit.addMediaFiles(files);
  },
)

// En CreatePostCubit
void createPost(String content) async {
  final responses = await uploadService.uploadMultipleXFile(mediaFiles);
  final mediaUrls = responses.map((r) => r.url).toList();
  await postService.createPost(content, mediaUrls);
}
```

### Competitions (Banner/Logo)
```dart
// En CompetitionsCubit._processImageFields
final imageFields = {'banner': bannerFile, 'logo': logoFile};
for (var entry in imageFields.entries) {
  final response = await uploadService.uploadImage(entry.value);
  competitionData[entry.key] = response.url;
}
```

---

## Troubleshooting One-Liners

```bash
# Ver archivos huérfanos
find uploads/ -type f -mtime +1 -name "*.jpg"

# Limpiar thumbnails
rm -rf uploads/thumbnails/*

# Ver tamaño de uploads
du -sh uploads/

# Contar archivos por tipo
find uploads/images -type f | wc -l
find uploads/videos -type f | wc -l

# Verificar permisos
ls -la uploads/
```

---

## Links Útiles

- **Guía Completa**: `./MEDIA_SYSTEM_GUIDE.md`
- **Config Backend**: `backend/config/media_config.go`
- **Config Frontend**: `lib/core/media/validators/media_validator.dart`
- **Endpoints**: `backend/features/media/routes.go`
- **Validación**: `backend/pkg/media/upload.go`

---

**Última actualización**: 2026-01-05
