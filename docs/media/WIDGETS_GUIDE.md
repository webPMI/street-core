# Media Widgets - Guía de Uso

Guía completa de los widgets optimizados del sistema de media con ejemplos prácticos.

---

## 📦 Importación

```dart
import 'package:street_core/core/media/widgets/media_widgets.dart';
```

---

## 🎨 Widgets de Progreso y Feedback

### AnimatedUploadProgress

Widget de progreso animado con efectos de pulsación y estados visuales.

**Características:**
- Animación suave de progreso (0.0 - 1.0)
- Efecto de pulsación mientras sube
- Estados: uploading, success, error
- Iconos animados para cada estado

**Ejemplo básico:**
```dart
AnimatedUploadProgress(
  progress: 0.75, // 75%
  status: UploadStatus.uploading,
  fileName: 'profile-photo.jpg',
  showPercentage: true,
  showFileName: true,
)
```

**Ejemplo con estados:**
```dart
// Durante la carga
AnimatedUploadProgress(
  progress: uploadProgress,
  status: UploadStatus.uploading,
)

// Éxito
AnimatedUploadProgress(
  progress: 1.0,
  status: UploadStatus.success,
)

// Error
AnimatedUploadProgress(
  progress: 0.0,
  status: UploadStatus.error,
)
```

**Personalización:**
```dart
AnimatedUploadProgress(
  progress: 0.5,
  status: UploadStatus.uploading,
  size: 150.0,           // Tamaño del círculo
  strokeWidth: 10.0,     // Grosor del borde
  showPercentage: true,  // Mostrar porcentaje
  showFileName: true,    // Mostrar nombre de archivo
)
```

### MediaUploadFeedback

Dialog de feedback completo con progreso, estados y acciones.

**Características:**
- Auto-dismiss en éxito (configurable)
- Botones de retry/cancel
- Integración con MediaUploadCubit
- Mensajes traducidos

**Ejemplo básico:**
```dart
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => BlocProvider.value(
    value: uploadCubit,
    child: MediaUploadFeedback(
      fileName: 'photo.jpg',
      autoDismissOnSuccess: true,
      dismissDelay: Duration(seconds: 2),
    ),
  ),
);
```

**Con callbacks personalizados:**
```dart
MediaUploadFeedback(
  fileName: selectedFile.name,
  onRetry: () {
    // Lógica de reintento personalizada
    uploadCubit.uploadImage(file);
  },
  onCancel: () {
    uploadCubit.cancelUpload();
    Navigator.pop(context);
  },
)
```

### FloatingUploadFeedback

Feedback flotante no intrusivo en la parte inferior de la pantalla.

**Características:**
- Menos intrusivo que un dialog
- Progress bar lineal
- Auto-oculta al completar
- Cancelable

**Ejemplo:**
```dart
Stack(
  children: [
    // Tu contenido principal
    YourMainContent(),

    // Feedback flotante
    BlocProvider.value(
      value: uploadCubit,
      child: FloatingUploadFeedback(
        fileName: 'documento.pdf',
      ),
    ),
  ],
)
```

---

## 🖼️ Widgets de Imágenes con Caché

### CachedMediaImage

Imagen optimizada con caché automático y efecto shimmer al cargar.

**Características:**
- Caché automático en disco
- Efecto shimmer mientras carga
- Widget de error personalizable
- Optimización de memoria

**Ejemplo básico:**
```dart
CachedMediaImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
)
```

**Con border radius:**
```dart
CachedMediaImage(
  imageUrl: imageUrl,
  width: 300,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
)
```

**Optimización de memoria:**
```dart
CachedMediaImage(
  imageUrl: largeImageUrl,
  width: 150,
  height: 150,
  // Limita el tamaño en caché de memoria a 2x el tamaño real
  memCacheWidth: 300,  // 150 * 2
  memCacheHeight: 300, // 150 * 2
)
```

**Placeholder y error personalizados:**
```dart
CachedMediaImage(
  imageUrl: url,
  placeholder: Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(color: Colors.white),
  ),
  errorWidget: Icon(Icons.error),
)
```

### CachedAvatarImage

Avatar circular con caché optimizado.

**Ejemplo:**
```dart
CachedAvatarImage(
  imageUrl: user.avatarUrl,
  size: 50.0,
)
```

**Con fallback personalizado:**
```dart
CachedAvatarImage(
  imageUrl: user.avatarUrl ?? '',
  size: 40.0,
  errorWidget: CircleAvatar(
    radius: 20,
    child: Text(user.initials),
  ),
)
```

### CachedThumbnailImage

Thumbnail optimizado para listas y grids.

**Ejemplo:**
```dart
CachedThumbnailImage(
  imageUrl: thumbnailUrl,
  size: 80.0,
  onTap: () => openFullImage(),
)
```

**En una grid:**
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 4,
    mainAxisSpacing: 4,
  ),
  itemBuilder: (context, index) => CachedThumbnailImage(
    imageUrl: images[index],
    size: 100,
    onTap: () => showFullImage(index),
  ),
)
```

---

## 🔍 Preview con Zoom

### ZoomableImagePreview

Vista de imagen a pantalla completa con zoom y gestos.

**Características:**
- Pinch to zoom (1x - 4x)
- Double tap to zoom
- Pan cuando está zoomeado
- Hero animation support
- Botón de cerrar

**Ejemplo básico:**
```dart
// Abrir preview
Navigator.push(
  context,
  PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black,
    pageBuilder: (context, _, __) => ZoomableImagePreview(
      imageUrl: imageUrl,
    ),
  ),
);
```

**Con Hero animation:**
```dart
// En tu thumbnail
Hero(
  tag: 'image_$index',
  child: CachedThumbnailImage(
    imageUrl: url,
    onTap: () => _openZoomPreview(index),
  ),
)

// Abrir preview con hero
void _openZoomPreview(int index) {
  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (context, _, __) => ZoomableImagePreview(
        imageUrl: images[index],
        heroTag: 'image_$index',
      ),
    ),
  );
}
```

**Desde archivo local:**
```dart
ZoomableImagePreview(
  imageFile: File('path/to/image.jpg'),
)
```

**Desde bytes (web):**
```dart
ZoomableImagePreview(
  imageBytes: uint8ListData,
)
```

**Personalización de zoom:**
```dart
ZoomableImagePreview(
  imageUrl: url,
  minScale: 1.0,
  maxScale: 5.0,
  doubleTapScale: 2.5,
)
```

---

## 📸 Galerías con Lazy Loading

### LazyMediaGallery

Grid de imágenes con lazy loading y optimización de memoria.

**Características:**
- Lazy loading (carga al hacer scroll)
- Caché automático
- Tap para zoom
- Hero animations
- Memory efficient

**Ejemplo básico:**
```dart
LazyMediaGallery(
  imageUrls: listOfImageUrls,
  columns: 3,
  spacing: 8.0,
)
```

**Con personalización:**
```dart
LazyMediaGallery(
  imageUrls: photoGallery,
  columns: 4,
  aspectRatio: 1.0,        // Cuadrado
  spacing: 4.0,
  maxCrossAxisExtent: 120, // Tamaño máximo de cada item
  heroTagPrefix: 'gallery', // Para hero animations
)
```

**Con callback personalizado:**
```dart
LazyMediaGallery(
  imageUrls: images,
  onImageTap: (index, url) {
    // Acción personalizada
    showImageDetails(images[index]);
  },
)
```

**En una página completa:**
```dart
class PhotoGalleryPage extends StatelessWidget {
  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Galería')),
      body: LazyMediaGallery(
        imageUrls: photos,
        columns: 3,
        spacing: 2.0,
        heroTagPrefix: 'photo',
      ),
    );
  }
}
```

### LazyMediaCarousel

Carousel horizontal con lazy loading.

**Características:**
- Scroll horizontal
- Lazy loading
- Aspect ratio configurable
- Tap para zoom

**Ejemplo básico:**
```dart
LazyMediaCarousel(
  imageUrls: carouselImages,
  height: 200,
)
```

**Personalizado:**
```dart
LazyMediaCarousel(
  imageUrls: featuredImages,
  height: 250,
  aspectRatio: 16 / 9,
  spacing: 12.0,
  heroTagPrefix: 'featured',
)
```

**En un PageView:**
```dart
Column(
  children: [
    // Header
    HeaderWidget(),

    // Carousel de destacados
    LazyMediaCarousel(
      imageUrls: featuredPhotos,
      height: 200,
      onImageTap: (index, url) {
        navigateToDetail(index);
      },
    ),

    // Resto del contenido
    ContentWidget(),
  ],
)
```

---

## 💡 Casos de Uso Completos

### Caso 1: Perfil con Avatar Editable

```dart
class ProfileHeader extends StatelessWidget {
  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar con caché
        Stack(
          children: [
            CachedAvatarImage(
              imageUrl: user.avatarUrl,
              size: 120,
            ),
            // Botón para editar
            Positioned(
              bottom: 0,
              right: 0,
              child: FloatingActionButton(
                mini: true,
                onPressed: () => _uploadNewAvatar(context),
                child: Icon(Icons.camera_alt),
              ),
            ),
          ],
        ),
        Text(user.name),
      ],
    );
  }

  Future<void> _uploadNewAvatar(BuildContext context) async {
    final cubit = context.read<MediaUploadCubit>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (file != null) {
      // Mostrar feedback
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => BlocProvider.value(
          value: cubit,
          child: MediaUploadFeedback(
            fileName: file.name,
            autoDismissOnSuccess: true,
          ),
        ),
      );

      // Subir avatar
      await cubit.uploadAvatar(File(file.path));
    }
  }
}
```

### Caso 2: Galería de Posts con Preview

```dart
class PostGalleryWidget extends StatelessWidget {
  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return SizedBox.shrink();

    if (imageUrls.length == 1) {
      // Una sola imagen
      return GestureDetector(
        onTap: () => _openPreview(context, 0),
        child: Hero(
          tag: 'post_image_0',
          child: CachedMediaImage(
            imageUrl: imageUrls[0],
            height: 300,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Múltiples imágenes - usar carousel
    return LazyMediaCarousel(
      imageUrls: imageUrls,
      height: 300,
      heroTagPrefix: 'post_image',
    );
  }

  void _openPreview(BuildContext context, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => ZoomableImagePreview(
          imageUrl: imageUrls[index],
          heroTag: 'post_image_$index',
        ),
      ),
    );
  }
}
```

### Caso 3: Upload con Progreso Animado

```dart
class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final MediaUploadCubit _uploadCubit = MediaUploadCubit(getIt());
  List<XFile> _selectedFiles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crear Post')),
      body: Stack(
        children: [
          // Contenido principal
          Column(
            children: [
              // Selector de archivos
              FileUploadWidget(
                maxFiles: 10,
                onFilesSelected: (files) async {
                  setState(() => _selectedFiles = files);
                },
              ),

              // Vista previa de seleccionados
              if (_selectedFiles.isNotEmpty)
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _selectedFiles.length,
                    itemBuilder: (context, index) {
                      return Image.file(
                        File(_selectedFiles[index].path),
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),

              // Botón de publicar
              ElevatedButton(
                onPressed: _selectedFiles.isNotEmpty ? _publishPost : null,
                child: Text('Publicar'),
              ),
            ],
          ),

          // Feedback flotante
          BlocProvider.value(
            value: _uploadCubit,
            child: FloatingUploadFeedback(),
          ),
        ],
      ),
    );
  }

  Future<void> _publishPost() async {
    // Subir archivos
    await _uploadCubit.uploadMultiple(_selectedFiles);

    // Escuchar resultado
    _uploadCubit.stream.listen((state) {
      if (state is MediaUploadMultipleSuccess) {
        // Éxito - crear post
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _uploadCubit.close();
    super.dispose();
  }
}
```

---

## ⚡ Tips de Rendimiento

### 1. Limita el tamaño de caché en memoria

```dart
// Bien ✅
CachedMediaImage(
  imageUrl: url,
  width: 100,
  height: 100,
  memCacheWidth: 200,  // 2x el tamaño real
  memCacheHeight: 200,
)

// Mal ❌ - desperdicia memoria
CachedMediaImage(
  imageUrl: url,
  width: 100,
  height: 100,
  // Sin límite de caché
)
```

### 2. Usa lazy loading para listas largas

```dart
// Bien ✅
LazyMediaGallery(
  imageUrls: hundreds_of_images,
  // Solo carga las visibles + buffer
)

// Mal ❌
GridView.builder(
  children: hundreds_of_images.map((url) =>
    Image.network(url) // Carga todo de inmediato
  ).toList(),
)
```

### 3. Reutiliza MediaUploadCubit

```dart
// Bien ✅ - Un cubit para toda la app
final uploadCubit = getIt<MediaUploadCubit>();

// Mal ❌ - Crear uno nuevo cada vez
final uploadCubit = MediaUploadCubit(uploadService);
```

---

## 🎯 Resumen de Widgets

| Widget | Uso | Optimización |
|--------|-----|--------------|
| `AnimatedUploadProgress` | Progreso de uploads | Animaciones suaves |
| `MediaUploadFeedback` | Feedback completo | Auto-dismiss |
| `FloatingUploadFeedback` | Feedback no intrusivo | Menos recursos |
| `CachedMediaImage` | Imágenes de red | Caché automático + shimmer |
| `CachedAvatarImage` | Avatares circulares | Caché optimizado |
| `CachedThumbnailImage` | Thumbnails en grids | Memory limit |
| `ZoomableImagePreview` | Preview a pantalla completa | Gestos nativos |
| `LazyMediaGallery` | Galería grid | Lazy loading |
| `LazyMediaCarousel` | Carousel horizontal | Lazy loading |

---

**Última actualización:** 2026-01-06
