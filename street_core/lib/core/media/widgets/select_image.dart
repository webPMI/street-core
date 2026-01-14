import 'dart:io' show File;

import '../../helpers/logger.dart';
import '../../helpers/snackbar_helper.dart';
import '../../lang/context_tr.dart';
import '../../lang/locale_keys.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/my_text.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// {@template image_picker_widget}
/// Widget reutilizable para seleccionar una sola imagen con preview.
///
/// Componente especializado en selección de imágenes con validación automática,
/// compresión, y soporte completo para web y móvil (cámara y galería).
///
/// ## Características Principales
///
/// | Categoría | Características |
/// |-----------|-----------------|
/// | **Fuentes** | Cámara, Galería (modal en móvil) |
/// | **Validación** | Tamaño, extensión, dimensiones |
/// | **Compresión** | Automática con calidad configurable |
/// | **Preview** | Imagen con botón de eliminar |
/// | **Estados** | Idle, Loading, Selected, Error |
///
/// ## Uso Básico
///
/// ```dart
/// ImagePickerWidget(
///   onImageSelected: (file) => print('Image: ${file?.path}'),
///   onImageSelectedWeb: (bytes) => print('Web: ${bytes?.length} bytes'),
///   width: 300,
///   height: 200,
/// )
/// ```
///
/// ## Con URL Inicial
///
/// ```dart
/// ImagePickerWidget(
///   initialImageUrl: 'https://example.com/avatar.jpg',
///   onImageSelected: handleImageChange,
/// )
/// ```
///
/// ## Configuración Personalizada
///
/// ```dart
/// ImagePickerWidget(
///   allowedExtensions: ['jpg', 'png'],
///   maxSizeBytes: 5 * 1024 * 1024, // 5MB
///   maxImageDimension: 1024,
///   imageQuality: 90,
///   placeholderText: 'custom_placeholder_key',
///   onImageSelected: handleImage,
/// )
/// ```
///
/// ## Estados Visuales
///
/// | Estado | Descripción |
/// |--------|-------------|
/// | **Idle** | Placeholder con icono |
/// | **Loading** | Spinner mientras procesa |
/// | **Selected** | Preview de la imagen |
/// | **Error** | Snackbar con mensaje |
///
/// ## Validaciones
///
/// - Extensión de archivo
/// - Tamaño máximo (default: 10MB)
/// - Compresión automática a dimensión máxima
///
/// {@endtemplate}
class ImagePickerWidget extends StatefulWidget {
  /// {@macro image_picker_widget}
  const ImagePickerWidget({
    super.key,
    required this.onImageSelected,
    this.onImageSelectedWeb,
    this.initialImageUrl,
    this.width = 300,
    this.height = 200,
    this.fit = BoxFit.cover,
    this.showDeleteButton = true,
    this.placeholderText,
    this.allowedExtensions = const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    this.maxSizeBytes = 10 * 1024 * 1024, // 10MB
    this.maxImageDimension = 1920,
    this.imageQuality = 85,
  });

  /// Callback cuando se selecciona una imagen (mobile)
  final Function(File?) onImageSelected;

  /// Callback cuando se selecciona una imagen (web)
  final Function(Uint8List?)? onImageSelectedWeb;

  /// URL de imagen inicial (opcional)
  final String? initialImageUrl;

  /// Ancho del widget
  final double? width;

  /// Alto del widget
  final double? height;

  /// Ajuste de la imagen
  final BoxFit fit;

  /// Mostrar botón de eliminar
  final bool showDeleteButton;

  /// Texto del placeholder (clave de traducción)
  final String? placeholderText;

  /// Extensiones de archivo permitidas (sin punto)
  final List<String> allowedExtensions;

  /// Tamaño máximo del archivo en bytes (default: 10MB)
  final int maxSizeBytes;

  /// Dimensión máxima de la imagen (ancho y alto)
  final double maxImageDimension;

  /// Calidad de compresión (0-100)
  final int imageQuality;

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  static const String _tag = 'ImagePickerWidget';

  File? _selectedImage;
  Uint8List? _webImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    AppLogger.debug(
      'Picking image from ${source == ImageSource.camera ? 'camera' : 'gallery'}',
      tag: _tag,
    );

    setState(() => _isLoading = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: widget.maxImageDimension,
        maxHeight: widget.maxImageDimension,
        imageQuality: widget.imageQuality,
      );

      if (pickedFile != null) {
        AppLogger.info('Image selected: ${pickedFile.name}', tag: _tag);

        // Validar extensión
        final extension = pickedFile.name.split('.').last.toLowerCase();
        if (!widget.allowedExtensions.contains(extension)) {
          AppLogger.warning('Invalid file type: $extension', tag: _tag);
          _showError(
            context.tr(
              LocaleKeys.mediaErrorInvalidFileType,
              args: {
                'type': extension,
                'allowed': widget.allowedExtensions.join(', '),
              },
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (kIsWeb) {
          await _processWebImage(pickedFile);
        } else {
          await _processMobileImage(pickedFile);
        }
      } else {
        AppLogger.debug('Image selection cancelled by user', tag: _tag);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to pick image',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      _showError(context.tr('error.selecting.image'));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processWebImage(XFile pickedFile) async {
    final bytes = await pickedFile.readAsBytes();

    // Validar tamaño
    if (bytes.length > widget.maxSizeBytes) {
      final sizeMB = (widget.maxSizeBytes / (1024 * 1024)).toStringAsFixed(0);
      AppLogger.warning(
        'File too large: ${pickedFile.name} (${bytes.length} bytes)',
        tag: _tag,
      );
      _showError(
        context.tr(
          LocaleKeys.mediaErrorFileTooLarge,
          args: {'size': sizeMB, 'name': pickedFile.name},
        ),
      );
      return;
    }

    AppLogger.debug('Web image loaded: ${bytes.length} bytes', tag: _tag);
    setState(() {
      _webImage = bytes;
    });
    if (widget.onImageSelectedWeb != null) {
      widget.onImageSelectedWeb!(bytes);
    }
    widget.onImageSelected(null);
  }

  Future<void> _processMobileImage(XFile pickedFile) async {
    final file = File(pickedFile.path);

    // Validar tamaño
    final fileSize = await file.length();
    if (fileSize > widget.maxSizeBytes) {
      final sizeMB = (widget.maxSizeBytes / (1024 * 1024)).toStringAsFixed(0);
      final fileName = pickedFile.name;
      AppLogger.warning(
        'File too large: $fileName ($fileSize bytes)',
        tag: _tag,
      );
      _showError(
        context.tr(LocaleKeys.mediaErrorFileTooLarge,
            args: {'size': sizeMB, 'name': fileName}),
      );
      return;
    }

    AppLogger.debug('Mobile image loaded: ${file.path}', tag: _tag);
    setState(() {
      _selectedImage = file;
    });
    widget.onImageSelected(file);
  }

  void _showError(String message) {
    if (mounted) {
      SnackBarHelper.showError(context, LocaleKeys.errorSelectingImage);
    }
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(context);

    // En web, solo mostramos la opción de galería
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }

    // En móvil, mostramos ambas opciones
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppSpacing.edgeInsetsLG,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_camera,
                  color: theme.colorScheme.primary,
                  size: AppIconSize.md,
                ),
                title: const MyText(LocaleKeys.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: theme.colorScheme.primary,
                  size: AppIconSize.md,
                ),
                title: const MyText(LocaleKeys.selectFromGallery),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.cancel,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: AppIconSize.md,
                ),
                title: const MyText(LocaleKeys.cancel),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteImage() {
    AppLogger.debug('Deleting selected image', tag: _tag);
    setState(() {
      _selectedImage = null;
      _webImage = null;
    });
    widget.onImageSelected(null);
    if (widget.onImageSelectedWeb != null) {
      widget.onImageSelectedWeb!(null);
    }
  }

  Widget _buildImageDisplay() {
    // Mostrar indicador de carga
    if (_isLoading) {
      return _buildLoadingState();
    }

    // Prioridad: imagen web > imagen móvil > imagen inicial > placeholder
    if (kIsWeb && _webImage != null) {
      return Image.memory(
        _webImage!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    } else if (!kIsWeb && _selectedImage != null) {
      return Image.file(
        _selectedImage!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    } else if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      return Image.network(
        widget.initialImageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          AppLogger.warning(
            'Failed to load network image: ${widget.initialImageUrl}',
            tag: _tag,
          );
          return _buildPlaceholder();
        },
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
           MyText(
            LocaleKeys.mediaImageProcessing,
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    final theme = Theme.of(context);

    return Container(
      padding: AppSpacing.edgeInsetsMD,
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: AppIconSize.xxl,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: AppSpacing.sm),
          MyText(
            widget.placeholderText ?? LocaleKeys.mediaImageSelect,
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool get _hasImage {
    if (kIsWeb) {
      return _webImage != null ||
          (widget.initialImageUrl != null &&
              widget.initialImageUrl!.isNotEmpty);
    } else {
      return _selectedImage != null ||
          (widget.initialImageUrl != null &&
              widget.initialImageUrl!.isNotEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImageDisplay(),
              ),
            ),
            if (_hasImage && widget.showDeleteButton)
              Positioned(
                top: 8,
                right: 8,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _deleteImage,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: widget.width,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _showImageSourceDialog,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate),
            label: MyText(
              _isLoading
                  ? LocaleKeys.mediaImageProcessing
                  : (_hasImage
                      ? LocaleKeys.mediaImageChange
                      : LocaleKeys.mediaImageSelect),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
