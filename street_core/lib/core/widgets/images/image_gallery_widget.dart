// lib/core/widgets/images/image_gallery_widget.dart

import '../../helpers/snackbar_helper.dart';
import '../../lang/context_tr.dart';
import '../../lang/locale_keys.dart';
import '../../theme/app_spacing.dart';
import '../my_card.dart';
import '../my_text.dart';
import 'package:flutter/material.dart';

/// ImageGalleryWidget - Widget avanzado para gestionar galerías de imágenes
///
/// Widget completo para manejar colecciones de imágenes con soporte para
/// upload múltiple, reordenamiento, eliminación y previsualización.
///
/// ## Características
///
/// - **Upload múltiple**: Agrega múltiples imágenes con límite configurable
/// - **Reordenamiento**: Marca cualquier imagen como principal
/// - **Eliminación individual**: Elimina imágenes de la galería
/// - **Vista en grid**: Preview responsive con aspect ratio configurable
/// - **Imagen principal**: La primera imagen se marca como principal
/// - **Soporte para URLs**: Compatible con imágenes de red
/// - **Estados de carga**: Indicadores visuales durante el upload
/// - **Manejo de errores**: Fallback visual para imágenes rotas
/// - **Accesibilidad**: Completo soporte de Semantics y tooltips
/// - **Animaciones**: Transiciones suaves entre estados
///
/// ## Uso Básico
///
/// ```dart
/// ImageGalleryWidget(
///   imageUrls: ['https://example.com/img1.jpg', 'https://example.com/img2.jpg'],
///   onChanged: (updatedUrls) {
///     setState(() => imageUrls = updatedUrls);
///   },
///   onUpload: () async {
///     // Implementa tu lógica de upload
///     final file = await picker.pickImage(source: ImageSource.gallery);
///     if (file != null) {
///       final url = await uploadToServer(file);
///       return url;
///     }
///     return null;
///   },
/// )
/// ```
///
/// ## Uso Avanzado
///
/// ```dart
/// ImageGalleryWidget(
///   imageUrls: productImages,
///   onChanged: (urls) => setState(() => productImages = urls),
///   onUpload: () async {
///     // Upload con validación y compresión
///     final file = await ImagePicker().pickImage(
///       source: ImageSource.gallery,
///       maxWidth: 1920,
///       maxHeight: 1080,
///       imageQuality: 85,
///     );
///
///     if (file != null) {
///       final compressed = await compressImage(file);
///       final url = await apiService.uploadProductImage(compressed);
///       return url;
///     }
///     return null;
///   },
///   maxImages: 8,
///   crossAxisCount: 4,
///   aspectRatio: 16 / 9,
///   canReorder: true,
///   canDelete: true,
///   canAdd: user.isPremium,
///   emptyMessage: 'product_images_empty',
/// )
/// ```
///
/// ## Con validación personalizada
///
/// ```dart
/// Future<String?> _handleImageUpload() async {
///   try {
///     final file = await picker.pickImage(source: ImageSource.gallery);
///     if (file == null) return null;
///
///     // Validar tamaño
///     final bytes = await file.readAsBytes();
///     if (bytes.length > 5 * 1024 * 1024) { // 5MB
///       showError('Image too large');
///       return null;
///     }
///
///     // Upload
///     final url = await uploadService.upload(file);
///     return url;
///   } catch (e) {
///     showError(e.toString());
///     return null;
///   }
/// }
///
/// ImageGalleryWidget(
///   imageUrls: clubImages,
///   onChanged: (urls) => setState(() => clubImages = urls),
///   onUpload: _handleImageUpload,
/// )
/// ```
///
/// ## Parámetros
///
/// - [imageUrls]: Lista de URLs de imágenes a mostrar
/// - [onChanged]: Callback cuando la lista de imágenes cambia
/// - [onUpload]: Callback para manejar el upload de nuevas imágenes
/// - [canReorder]: Permite marcar imágenes como principal (default: true)
/// - [canDelete]: Permite eliminar imágenes (default: true)
/// - [canAdd]: Muestra botón para agregar imágenes (default: true)
/// - [maxImages]: Número máximo de imágenes permitidas (default: 10)
/// - [emptyMessage]: Mensaje cuando no hay imágenes (default: 'no_images_add_one')
/// - [aspectRatio]: Relación de aspecto de las miniaturas (default: 1.0)
/// - [crossAxisCount]: Número de columnas en el grid (default: 3)
///
/// See also:
///
/// - [OptimizedImage] para mostrar imágenes individuales optimizadas
/// - [FileUploadWidget] para upload de archivos genéricos
/// - [SelectImage] para seleccionar imágenes del dispositivo
class ImageGalleryWidget extends StatefulWidget {
  const ImageGalleryWidget({
    super.key,
    required this.imageUrls,
    required this.onChanged,
    this.onUpload,
    this.canReorder = true,
    this.canDelete = true,
    this.canAdd = true,
    this.maxImages = 10,
    this.emptyMessage = 'no_images_add_one',
    this.aspectRatio = 1.0,
    this.crossAxisCount = 3,
  });

  /// Lista actual de URLs de imágenes
  final List<String> imageUrls;

  /// Callback ejecutado cuando la lista de imágenes cambia
  ///
  /// Recibe la nueva lista de URLs actualizada
  final ValueChanged<List<String>> onChanged;

  /// Callback para manejar el upload de nuevas imágenes
  ///
  /// Debe retornar la URL de la imagen subida o null si falló/se canceló
  final Future<String?> Function()? onUpload;

  /// Permite reordenar y marcar imágenes como principal
  final bool canReorder;

  /// Permite eliminar imágenes de la galería
  final bool canDelete;

  /// Muestra botón para agregar nuevas imágenes
  final bool canAdd;

  /// Número máximo de imágenes permitidas en la galería
  final int maxImages;

  /// Mensaje traducible a mostrar cuando la galería está vacía
  final String emptyMessage;

  /// Relación de aspecto para las miniaturas (width/height)
  ///
  /// - 1.0 para cuadrado
  /// - 16/9 para landscape
  /// - 9/16 para portrait
  final double aspectRatio;

  /// Número de columnas en el grid de miniaturas
  final int crossAxisCount;

  @override
  State<ImageGalleryWidget> createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget>
    with SingleTickerProviderStateMixin {
  late List<String> _images;
  bool _isUploading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.imageUrls);

    // Configurar animación
    _animationController = AnimationController(
      vsync: this,
      duration: AppDuration.normal,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(ImageGalleryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      setState(() {
        _images = List.from(widget.imageUrls);
      });
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Maneja el proceso de upload de una nueva imagen
  Future<void> _handleUpload() async {
    if (widget.onUpload == null) return;
    if (_images.length >= widget.maxImages) {
      if (!mounted) return;
      SnackBarHelper.showWarning(context, LocaleKeys.maxImagesAllowed);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final newUrl = await widget.onUpload!();
      if (newUrl != null && newUrl.isNotEmpty && mounted) {
        setState(() {
          _images.add(newUrl);
        });
        widget.onChanged(_images);
        _animationController.forward(from: 0.0);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Elimina una imagen de la galería
  void _deleteImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onChanged(_images);
    _animationController.forward(from: 0.0);
  }

  /// Mueve una imagen a la primera posición (marca como principal)
  void _moveImageToFirst(int index) {
    if (index == 0) return;
    setState(() {
      final image = _images.removeAt(index);
      _images.insert(0, image);
    });
    widget.onChanged(_images);
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: context.tr(LocaleKeys.imageGallery),
      container: true,
      child: MyResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(colorScheme),

            SizedBox(height: AppSpacing.md),

            // Image counter
            _buildImageCounter(colorScheme),

            SizedBox(height: AppSpacing.md),

            // Grid or empty state
            FadeTransition(
              opacity: _fadeAnimation,
              child: _images.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : _buildImageGrid(),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el encabezado con título y botón de agregar
  Widget _buildHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.photo_library,
              color: colorScheme.primary,
              size: AppIconSize.md,
            ),
            SizedBox(width: AppSpacing.sm),
            const MyText(LocaleKeys.imageGallery, istitle: true),
          ],
        ),
        if (widget.canAdd && _images.length < widget.maxImages)
          Semantics(
            button: true,
            label: context.tr(LocaleKeys.add),
            enabled: !_isUploading,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _handleUpload,
              icon: _isUploading
                  ? SizedBox(
                      width: AppIconSize.xs,
                      height: AppIconSize.xs,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.add_photo_alternate,
                      size: AppIconSize.sm,
                    ),
              label: const MyText(LocaleKeys.add),
            ),
          ),
      ],
    );
  }

  /// Construye el contador de imágenes
  Widget _buildImageCounter(ColorScheme colorScheme) {
    return Semantics(
      label: context.tr(LocaleKeys.imagesOf, args: {
        'count': _images.length.toString(),
        'total': widget.maxImages.toString()
      }),
      readOnly: true,
      child: Row(
        children: [
          Icon(
            Icons.image,
            size: AppIconSize.sm,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppSpacing.xs),
          MyText(
            LocaleKeys.imagesOf,
            args: {
              'count': _images.length.toString(),
              'total': widget.maxImages.toString()
            },
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppSpacing.sm),
          // Indicador de progreso visual
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.borderRadiusFull,
              child: LinearProgressIndicator(
                value: _images.length / widget.maxImages,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
                minHeight: AppSpacing.xs,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el estado vacío cuando no hay imágenes
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Semantics(
      label: widget.emptyMessage,
      container: true,
      child: Center(
        child: Padding(
          padding: AppSpacing.edgeInsetsXL,
          child: Column(
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: AppIconSize.xxl,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: AppSpacing.md),
              MyText(
                widget.emptyMessage,
                color: colorScheme.onSurfaceVariant,
                textAlign: TextAlign.center,
              ),
              if (widget.canAdd && widget.onUpload != null) ...[
                SizedBox(height: AppSpacing.md),
                Semantics(
                  button: true,
                  label: context.tr(LocaleKeys.addFirstImage),
                  child: OutlinedButton.icon(
                    onPressed: _handleUpload,
                    icon: Icon(Icons.add, size: AppIconSize.sm),
                    label: const MyText(LocaleKeys.addFirstImage),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el grid de imágenes
  Widget _buildImageGrid() {
    return Semantics(
      label: context.tr(LocaleKeys.imageGalleryCount,
          args: {'count': _images.length.toString()}),
      container: true,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: widget.aspectRatio,
        ),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          return _buildImageCard(index);
        },
      ),
    );
  }

  /// Construye una tarjeta individual de imagen
  Widget _buildImageCard(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMainImage = index == 0;

    return Semantics(
      label: context.tr(
          isMainImage
              ? LocaleKeys.mainImageNumber
              : LocaleKeys.imageNumber,
          args: {'number': (index + 1).toString()}),
      image: true,
      container: true,
      child: AnimatedScale(
        scale: 1.0,
        duration: AppDuration.fast,
        curve: Curves.easeInOut,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image con animación de entrada
            _buildImage(index, colorScheme),

            // Main image badge
            if (isMainImage) _buildMainBadge(colorScheme),

            // Actions overlay
            _buildActionsOverlay(index, isMainImage),
          ],
        ),
      ),
    );
  }

  /// Construye la imagen con estados de carga y error
  Widget _buildImage(int index, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: AppRadius.borderRadiusSM,
      child: Image.network(
        _images[index],
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  color: colorScheme.error,
                  size: AppIconSize.lg,
                ),
                SizedBox(height: AppSpacing.xs),
                 MyText(
                  LocaleKeys.error,
                  textAlign: TextAlign.center,
                  color: colorScheme.error,
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return AnimatedOpacity(
              opacity: 1.0,
              duration: AppDuration.fast,
              child: child,
            );
          }
          return Container(
            color: colorScheme.surfaceContainerHighest,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: colorScheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construye la insignia de "imagen principal"
  Widget _buildMainBadge(ColorScheme colorScheme) {
    return Positioned(
      top: AppSpacing.xs,
      left: AppSpacing.xs,
      child: Semantics(
        label: context.tr(LocaleKeys.main),
        readOnly: true,
        child: AnimatedContainer(
          duration: AppDuration.fast,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xs + AppSpacing.xxs,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: AppRadius.borderRadiusXS,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.2),
                blurRadius: AppElevation.sm,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: AppIconSize.xs,
                color: colorScheme.onPrimary,
              ),
              SizedBox(width: AppSpacing.xxs),
               MyText(
                LocaleKeys.main,
                color: colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la capa de acciones (eliminar y marcar como principal)
  Widget _buildActionsOverlay(int index, bool isMainImage) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: AppSpacing.xs,
      right: AppSpacing.xs,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Delete button
          if (widget.canDelete)
            _buildActionButton(
              icon: Icons.delete,
              label: context.tr(LocaleKeys.delete),
              onPressed: () => _deleteImage(index),
              colorScheme: colorScheme,
            ),

          // Set as main button
          if (widget.canReorder && !isMainImage) ...[
            SizedBox(height: AppSpacing.xs),
            _buildActionButton(
              icon: Icons.star,
              label: context.tr(LocaleKeys.markAsMain),
              onPressed: () => _moveImageToFirst(index),
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }

  /// Construye un botón de acción individual
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: AppElevation.sm,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: colorScheme.onSurface),
          iconSize: AppIconSize.sm,
          padding: AppSpacing.edgeInsetsXS,
          constraints: const BoxConstraints(),
          tooltip: label,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
