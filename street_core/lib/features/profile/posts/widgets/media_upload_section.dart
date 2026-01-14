// lib/presentation/dashboard/posts/widgets/media_upload_section.dart

import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/helpers/snackbar_helper.dart';

/// Widget para seleccionar y previsualizar archivos multimedia
/// Uses XFile for cross-platform compatibility (web, mobile, desktop)
class MediaUploadSection extends StatefulWidget {
  const MediaUploadSection({
    super.key,
    required this.selectedFiles,
    required this.onFilesSelected,
    required this.onRemoveFile,
    this.maxFiles = 10,
  });

  final List<XFile> selectedFiles;
  final Function(List<XFile>) onFilesSelected;
  final Function(int) onRemoveFile;
  final int maxFiles;

  @override
  State<MediaUploadSection> createState() => _MediaUploadSectionState();
}

class _MediaUploadSectionState extends State<MediaUploadSection> {
  // Cache for loaded image bytes (for preview)
  final Map<String, Uint8List> _imageCache = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview grid
        if (widget.selectedFiles.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: widget.selectedFiles.length,
            itemBuilder: _buildMediaPreview,
          ),

        const SizedBox(height: 12),

        // Botones para agregar archivos
        Row(
          children: [
            // Botón de cámara (solo en móvil)
            if (!kIsWeb)
              OutlinedButton.icon(
                onPressed: () => _pickMedia(context, ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
              ),

            if (!kIsWeb) const SizedBox(width: 12),

            // Botón de galería
            OutlinedButton.icon(
              onPressed: () => _pickMedia(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galería'),
            ),
          ],
        ),

        // Contador de archivos
        if (widget.selectedFiles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${widget.selectedFiles.length}/${widget.maxFiles} archivos seleccionados',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaPreview(BuildContext context, int index) {
    final file = widget.selectedFiles[index];
    final extension = file.name.split('.').last.toLowerCase();
    final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Preview
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isVideo
              ? Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.videocam,
                    size: 48,
                    color: Colors.grey,
                  ),
                )
              : _buildImagePreview(file),
        ),

        // File info overlay (bottom)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: FutureBuilder<int>(
              future: file.length(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final sizeMB = snapshot.data! / (1024 * 1024);
                final sizeText = sizeMB < 1
                    ? '${(sizeMB * 1024).toStringAsFixed(0)} KB'
                    : '${sizeMB.toStringAsFixed(1)} MB';

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isVideo)
                      const Icon(
                        Icons.videocam,
                        size: 12,
                        color: Colors.white,
                      ),
                    if (!isVideo && index == 0)
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                    const Spacer(),
                    Text(
                      sizeText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => widget.onRemoveFile(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Cover image badge
        if (index == 0 && !isVideo)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 10,
                    color: Colors.white,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'Portada',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Build image preview using Image.memory (works on all platforms)
  Widget _buildImagePreview(XFile file) {
    final cacheKey = file.path;

    // Check cache first
    if (_imageCache.containsKey(cacheKey)) {
      return Image.memory(
        _imageCache[cacheKey]!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    }

    // Load bytes asynchronously
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorPlaceholder();
        }

        // Cache the loaded bytes
        _imageCache[cacheKey] = snapshot.data!;

        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        );
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.broken_image,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  Future<void> _pickMedia(BuildContext context, ImageSource source) async {
    if (widget.selectedFiles.length >= widget.maxFiles) {
      SnackBarHelper.showWarning(context, 'max_files_allowed');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();

      if (source == ImageSource.camera) {
        // Seleccionar de la cámara (una sola)
        final XFile? photo = await picker.pickImage(source: source);
        if (photo != null) {
          // Validate file size
          if (!await _validateFileSize(context, photo)) {
            return;
          }
          widget.onFilesSelected([...widget.selectedFiles, photo]);
        }
      } else {
        // Seleccionar múltiples de la galería
        final List<XFile> images = await picker.pickMultiImage();
        if (images.isNotEmpty) {
          final totalFiles = widget.selectedFiles.length + images.length;

          if (totalFiles > widget.maxFiles) {
            if (context.mounted) {
              SnackBarHelper.showWarning(context, 'max_files_exceeded');
            }
            return;
          }

          // Validate each file size
          final List<XFile> validFiles = [];
          for (final image in images) {
            if (await _validateFileSize(context, image)) {
              validFiles.add(image);
            }
          }

          if (validFiles.isEmpty && context.mounted) {
            SnackBarHelper.showError(context, 'all_files_too_large');
            return;
          }

          if (validFiles.length < images.length && context.mounted) {
            SnackBarHelper.showWarning(
              context,
              'some_files_skipped',
            );
          }

          widget.onFilesSelected([...widget.selectedFiles, ...validFiles]);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'error.selecting.files');
      }
    }
  }

  /// Validate file size before adding
  /// Returns true if file is valid, false otherwise
  Future<bool> _validateFileSize(BuildContext context, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final sizeMB = bytes.length / (1024 * 1024);

      // Determine max size based on file type
      const maxImageSizeMB = 10.0; // 10MB for images
      const maxVideoSizeMB = 50.0; // 50MB for videos

      final extension = file.name.split('.').last.toLowerCase();
      final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);

      final maxSize = isVideo ? maxVideoSizeMB : maxImageSizeMB;

      if (sizeMB > maxSize) {
        if (context.mounted) {
          final message = isVideo
              ? 'file_too_large_video'
              : 'file_too_large_image';
          SnackBarHelper.showError(context, message);
        }
        return false;
      }

      return true;
    } catch (e) {
      // If we can't read the file, allow it and let backend handle it
      return true;
    }
  }
}
