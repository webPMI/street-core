// lib/core/widgets/upload/file_upload_widget.dart

import 'dart:io' show File;

import '/core/helpers/logger.dart';
import '/core/helpers/snackbar_helper.dart';
import '/core/lang/context_tr.dart';
import '/core/theme/app_spacing.dart';
import '/core/lang/locale_keys.dart';
import '../my_text.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// {@template file_upload_widget}
/// Widget profesional de carga de archivos con preview y validación.
///
/// Un componente completo para seleccionar y cargar archivos, con soporte para
/// web y móvil, validación de tamaño y tipo, y vista previa de imágenes.
///
/// ## Características Principales
///
/// | Categoría | Características |
/// |-----------|-----------------|
/// | **Plataformas** | Web, Android, iOS (imagen picker unificado) |
/// | **Validación** | Tamaño, extensión, cantidad de archivos |
/// | **Preview** | Miniaturas con overlay y botón de eliminar |
/// | **Estados** | Idle, Selecting, Selected, Error |
/// | **Animaciones** | Transiciones suaves, hover effects |
///
/// ## Uso Básico
///
/// ```dart
/// FileUploadWidget(
///   maxFiles: 5,
///   allowedExtensions: ['jpg', 'png', 'jpeg'],
///   maxSizeBytes: 10 * 1024 * 1024, // 10MB
///   onFilesSelected: (files) {
///     print('Selected ${files.length} files');
///   },
///   onFilesSelectedWeb: (webFiles) {
///     print('Selected ${webFiles.length} web files');
///   },
/// )
/// ```
///
/// ## Con Cámara (Solo móvil)
///
/// ```dart
/// FileUploadWidget(
///   imageSource: ImageSource.camera,
///   maxFiles: 1,
///   onFilesSelected: (files) => handlePhoto(files.first),
/// )
/// ```
///
/// ## Validación Personalizada
///
/// ```dart
/// FileUploadWidget(
///   maxFiles: 10,
///   allowedExtensions: ['pdf', 'doc', 'docx'],
///   maxSizeBytes: 5 * 1024 * 1024, // 5MB
///   title: 'upload_documents',
///   hint: 'select_pdf_files',
///   onFilesSelected: handleDocuments,
/// )
/// ```
///
/// ## Estados Visuales
///
/// | Estado | Descripción | UI |
/// |--------|-------------|-----|
/// | **Idle** | Sin archivos seleccionados | Icono de upload + hint |
/// | **Selecting** | Seleccionando archivos | Spinner + mensaje |
/// | **Selected** | Archivos seleccionados | Grid de previews |
/// | **Error** | Error de validación | Snackbar rojo |
///
/// ## Validaciones Automáticas
///
/// - **Cantidad**: No exceder `maxFiles`
/// - **Tamaño**: No exceder `maxSizeBytes` por archivo
/// - **Extensión**: Solo archivos en `allowedExtensions`
///
/// ## Accesibilidad
///
/// - ✅ Semantics para lectores de pantalla
/// - ✅ Mensajes de error descriptivos
/// - ✅ Estados visuales claros
/// - ✅ Navegación por teclado (web)
///
/// {@endtemplate}
class FileUploadWidget extends StatefulWidget {
  /// {@macro file_upload_widget}
  const FileUploadWidget({
    super.key,
    required this.onFilesSelected,
    this.onFilesSelectedWeb,
    this.maxFiles = 1,
    this.allowedExtensions = const ['jpg', 'png', 'jpeg'],
    this.maxSizeBytes = 10 * 1024 * 1024, // 10MB
    this.title = 'select_files',
    this.hint = 'tap_to_select',
    this.showPreview = true,
    this.imageSource,
  });

  /// Callback cuando se seleccionan archivos (mobile)
  final Function(List<File> files) onFilesSelected;

  /// Callback cuando se seleccionan archivos (web)
  final Function(List<WebFile>)? onFilesSelectedWeb;

  /// Número máximo de archivos permitidos
  final int maxFiles;

  /// Extensiones de archivo permitidas (sin punto)
  final List<String> allowedExtensions;

  /// Tamaño máximo del archivo en bytes (default: 10MB)
  final int maxSizeBytes;

  /// Título del widget (clave de traducción)
  final String title;

  /// Texto de sugerencia (clave de traducción)
  final String hint;

  /// Mostrar vista previa de imágenes
  final bool showPreview;

  /// Fuente de imagen (cámara o galería) - solo móvil
  final ImageSource? imageSource;

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

/// Represents a file selected in web environment
class WebFile {
  WebFile({required this.name, required this.bytes, required this.extension});
  final String name;
  final Uint8List bytes;
  final String extension;

  int get size => bytes.length;
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  static const String _tag = 'FileUploadWidget';

  List<File> _selectedFiles = [];
  List<WebFile> _selectedWebFiles = [];
  bool _isSelecting = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _selectFiles() async {
    AppLogger.debug('Starting file selection', tag: _tag);
    setState(() => _isSelecting = true);

    try {
      if (kIsWeb) {
        await _selectFilesWeb();
      } else {
        await _selectFilesMobile();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to select files',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      _showError(context.tr(LocaleKeys.mediaErrorSelectingFiles));
    } finally {
      setState(() => _isSelecting = false);
    }
  }

  Future<void> _selectFilesWeb() async {
    AppLogger.debug('Selecting files for Web platform', tag: _tag);

    // Multiple image selection from gallery
    if (widget.maxFiles == 1) {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final webFile = WebFile(
          name: image.name,
          bytes: bytes,
          extension: image.name.split('.').last.toLowerCase(),
        );
        await _addWebFile(webFile);
      } else {
        AppLogger.debug('File selection cancelled by user', tag: _tag);
      }
    } else {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        AppLogger.info('Selected ${images.length} files on Web', tag: _tag);
        final webFiles = <WebFile>[];
        for (final image in images) {
          final bytes = await image.readAsBytes();
          webFiles.add(
            WebFile(
              name: image.name,
              bytes: bytes,
              extension: image.name.split('.').last.toLowerCase(),
            ),
          );
        }
        await _validateAndAddWebFiles(webFiles);
      } else {
        AppLogger.debug('File selection cancelled by user', tag: _tag);
      }
    }
  }

  Future<void> _selectFilesMobile() async {
    AppLogger.debug('Selecting files for Mobile platform', tag: _tag);

    // If image source is specified, use camera or gallery
    if (widget.imageSource != null) {
      final XFile? image = await _picker.pickImage(
        source: widget.imageSource!,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        await _addFile(file);
      } else {
        AppLogger.debug('File selection cancelled by user', tag: _tag);
      }
    } else {
      // Multiple image selection from gallery
      if (widget.maxFiles == 1) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (image != null) {
          final file = File(image.path);
          await _addFile(file);
        } else {
          AppLogger.debug('File selection cancelled by user', tag: _tag);
        }
      } else {
        final List<XFile> images = await _picker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (images.isNotEmpty) {
          AppLogger.info(
            'Selected ${images.length} files on Mobile',
            tag: _tag,
          );
          final files = images.map((xFile) => File(xFile.path)).toList();
          await _validateAndAddFiles(files);
        } else {
          AppLogger.debug('File selection cancelled by user', tag: _tag);
        }
      }
    }
  }

  Future<void> _addFile(File file) async {
    AppLogger.debug('Adding single file: ${file.path}', tag: _tag);
    final validFiles = await _validateFiles([file]);
    if (validFiles.isNotEmpty) {
      AppLogger.info('File validated successfully: ${file.path}', tag: _tag);
      setState(() {
        _selectedFiles = validFiles;
      });
      widget.onFilesSelected(_selectedFiles);
    }
  }

  Future<void> _addWebFile(WebFile file) async {
    AppLogger.debug('Adding single web file: ${file.name}', tag: _tag);
    final validFiles = await _validateWebFiles([file]);
    if (validFiles.isNotEmpty) {
      AppLogger.info(
        'Web file validated successfully: ${file.name}',
        tag: _tag,
      );
      setState(() {
        _selectedWebFiles = validFiles;
      });
      widget.onFilesSelectedWeb?.call(_selectedWebFiles);
    }
  }

  Future<void> _validateAndAddFiles(List<File> files) async {
    AppLogger.debug('Validating ${files.length} files', tag: _tag);
    final validFiles = await _validateFiles(files);
    if (validFiles.isNotEmpty) {
      AppLogger.info(
        '${validFiles.length}/${files.length} files validated',
        tag: _tag,
      );
      setState(() {
        _selectedFiles = validFiles;
      });
      widget.onFilesSelected(_selectedFiles);
    }
  }

  Future<void> _validateAndAddWebFiles(List<WebFile> files) async {
    AppLogger.debug('Validating ${files.length} web files', tag: _tag);
    final validFiles = await _validateWebFiles(files);
    if (validFiles.isNotEmpty) {
      AppLogger.info(
        '${validFiles.length}/${files.length} web files validated',
        tag: _tag,
      );
      setState(() {
        _selectedWebFiles = validFiles;
      });
      widget.onFilesSelectedWeb?.call(_selectedWebFiles);
    }
  }

  Future<List<File>> _validateFiles(List<File> files) async {
    final valid = <File>[];

    for (final file in files) {
      // Check if we've reached max files
      if (valid.length >= widget.maxFiles) {
        AppLogger.warning(
          'Maximum files limit reached: ${widget.maxFiles}',
          tag: _tag,
        );
        _showError(
          context.tr(
            LocaleKeys.mediaErrorMaxFilesExceeded,
            args: {'count': widget.maxFiles.toString()},
          ),
        );
        break;
      }

      // Check size
      try {
        final size = await file.length();
        if (size > widget.maxSizeBytes) {
          final sizeMB = (widget.maxSizeBytes / (1024 * 1024)).toStringAsFixed(
            0,
          );
          final fileName = file.path.split('/').last;
          // ignore: unnecessary_brace_in_string_interps
          AppLogger.warning(
            'File too large: $fileName ($size bytes)',
            tag: _tag,
          );
          _showError(
            context.tr(
              LocaleKeys.mediaErrorFileTooLarge,
              args: {'size': sizeMB, 'name': fileName},
            ),
          );
          continue;
        }
      } catch (e, stackTrace) {
        final fileName = file.path.split('/').last;
        AppLogger.error(
          'Error reading file: $fileName',
          error: e,
          stackTrace: stackTrace,
          tag: _tag,
        );
        _showError(
            context.tr(LocaleKeys.mediaErrorReadingFile, args: {'name': fileName}));
        continue;
      }

      // Check extension
      final ext = file.path.split('.').last.toLowerCase();
      if (!widget.allowedExtensions.contains(ext)) {
        AppLogger.warning('Invalid file type: $ext', tag: _tag);
        _showError(
          context.tr(
            LocaleKeys.mediaErrorInvalidFileType,
            args: {'type': ext, 'allowed': widget.allowedExtensions.join(', ')},
          ),
        );
        continue;
      }

      valid.add(file);
    }

    return valid;
  }

  Future<List<WebFile>> _validateWebFiles(List<WebFile> files) async {
    final valid = <WebFile>[];

    for (final file in files) {
      // Check if we've reached max files
      if (valid.length >= widget.maxFiles) {
        AppLogger.warning(
          'Maximum files limit reached: ${widget.maxFiles}',
          tag: _tag,
        );
        _showError(
          context.tr(
            LocaleKeys.mediaErrorMaxFilesExceeded,
            args: {'count': widget.maxFiles.toString()},
          ),
        );
        break;
      }

      // Check size
      if (file.size > widget.maxSizeBytes) {
        final sizeMB = (widget.maxSizeBytes / (1024 * 1024)).toStringAsFixed(0);
        AppLogger.warning(
          'Web file too large: ${file.name} (${file.size} bytes)',
          tag: _tag,
        );
        _showError(
          context.tr(
            LocaleKeys.mediaErrorFileTooLarge,
            args: {'size': sizeMB, 'name': file.name},
          ),
        );
        continue;
      }

      // Check extension
      if (!widget.allowedExtensions.contains(file.extension)) {
        AppLogger.warning(
          'Invalid web file type: ${file.extension}',
          tag: _tag,
        );
        _showError(
          context.tr(
            LocaleKeys.mediaErrorInvalidFileType,
            args: {
              'type': file.extension,
              'allowed': widget.allowedExtensions.join(', '),
            },
          ),
        );
        continue;
      }

      valid.add(file);
    }

    return valid;
  }

  void _removeFile(File file) {
    AppLogger.debug('Removing file: ${file.path}', tag: _tag);
    setState(() {
      _selectedFiles.remove(file);
    });
    widget.onFilesSelected(_selectedFiles);
  }

  void _removeWebFile(WebFile file) {
    AppLogger.debug('Removing web file: ${file.name}', tag: _tag);
    setState(() {
      _selectedWebFiles.remove(file);
    });
    widget.onFilesSelectedWeb?.call(_selectedWebFiles);
  }

  void _showError(String message) {
    if (mounted) {
      SnackBarHelper.showError(context, LocaleKeys.mediaErrorSelectingFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: AppDuration.fast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        color: theme.cardColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelecting ? null : _selectFiles,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: AppSpacing.edgeInsetsMD,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  bool get _hasSelectedFiles =>
      kIsWeb ? _selectedWebFiles.isNotEmpty : _selectedFiles.isNotEmpty;

  int get _selectedFilesCount =>
      kIsWeb ? _selectedWebFiles.length : _selectedFiles.length;

  Widget _buildContent() {
    if (_isSelecting) {
      return _buildLoadingState();
    }

    if (!_hasSelectedFiles) {
      return _buildEmptyState();
    }

    if (widget.showPreview) {
      return _buildPreviewState();
    }

    return _buildFileListState();
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        SizedBox(height: AppSpacing.md),
        const MyText(LocaleKeys.mediaSelectSelectingFiles),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: AppIconSize.xl,
          color: theme.colorScheme.primary,
        ),
        SizedBox(height: AppSpacing.md),
        MyText(widget.title, fontSize: 16, fontWeight: FontWeight.w600),
        SizedBox(height: AppSpacing.xs),
        MyText(
          widget.hint,
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          '${context.tr(LocaleKeys.mediaMax)} ${widget.maxFiles} ${context.tr(widget.maxFiles > 1 ? LocaleKeys.mediaFileFiles : LocaleKeys.mediaFileFile)} • ${_formatBytes(widget.maxSizeBytes)}',
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(text: '$_selectedFilesCount '),
                  TextSpan(
                      text: context.tr(_selectedFilesCount > 1
                          ? LocaleKeys.mediaHintFilesSelected
                          : LocaleKeys.mediaHintFileSelected)),
                ],
              ),
            ),
            if (_selectedFilesCount < widget.maxFiles)
              TextButton.icon(
                onPressed: _selectFiles,
                icon: const Icon(Icons.add, size: AppIconSize.xs),
                label: const MyText(LocaleKeys.mediaSelectAddMore),
              ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: kIsWeb
              ? _selectedWebFiles.map(_buildWebPreviewItem).toList()
              : _selectedFiles.map(_buildPreviewItem).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewItem(File file) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: AppDuration.fast,
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.file(
              file,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: AppIconSize.lg,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          // Gradient overlay for better button visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _removeFile(file),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: theme.colorScheme.onError,
                    size: AppIconSize.xs,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebPreviewItem(WebFile file) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: AppDuration.fast,
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.memory(
              file.bytes,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: AppIconSize.lg,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          // Gradient overlay for better button visibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Remove button
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _removeWebFile(file),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.close,
                    color: theme.colorScheme.onError,
                    size: AppIconSize.xs,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileListState() {
    if (kIsWeb) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: _selectedWebFiles.map((file) {
          return ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(file.name),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _removeWebFile(file),
            ),
          );
        }).toList(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _selectedFiles.map((file) {
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(file.path.split('/').last),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _removeFile(file),
          ),
        );
      }).toList(),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
