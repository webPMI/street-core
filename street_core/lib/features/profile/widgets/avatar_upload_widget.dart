import 'dart:io' show File;
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/widgets/my_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:street_core/core/lang/locale_keys.dart';

/// Widget reutilizable para upload de avatar
///
/// Características:
/// - Muestra avatar actual en formato circular
/// - Botón overlay para cambiar foto
/// - Selección desde galería o cámara
/// - Preview de la nueva imagen
/// - Loading indicator durante upload
/// - Callback con File seleccionado (sin hacer upload automático)
class AvatarUploadWidget extends StatefulWidget {
  const AvatarUploadWidget({
    super.key,
    this.currentAvatarUrl,
    required this.onImageSelected,
    this.onImageSelectedWeb,
    this.size = 120,
    this.isLoading = false,
  });

  /// URL del avatar actual del usuario
  final String? currentAvatarUrl;

  /// Callback cuando se selecciona una nueva imagen
  /// Retorna el File seleccionado (móvil) o null si es cancelado
  final Function(File? file) onImageSelected;

  /// Callback para web (opcional) - incluye filename para mantener extensión correcta
  final Function(Uint8List? bytes, String? filename)? onImageSelectedWeb;

  /// Tamaño del avatar circular (default: 120)
  final double size;

  /// Mostrar loading indicator
  final bool isLoading;

  @override
  State<AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends State<AvatarUploadWidget> {
  File? _selectedImage;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (pickedFile == null) return;
      if (!mounted) return;

      if (kIsWeb) {
        // Para web, usamos bytes
        final bytes = await pickedFile.readAsBytes();
        if (!mounted) return;
        setState(() {
          _webImage = bytes;
          _selectedImage = null;
        });
        if (widget.onImageSelectedWeb != null) {
          // Pasar filename para mantener la extensión correcta
          widget.onImageSelectedWeb!(bytes, pickedFile.name);
        }
        // También llamamos al callback principal con null en web
        widget.onImageSelected(null);
      } else {
        // Para móvil (Android/iOS), usamos File
        final file = File(pickedFile.path);
        setState(() {
          _selectedImage = file;
          _webImage = null;
        });
        widget.onImageSelected(file);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'error.selecting.image');
      }
    }
  }

  void _showImageSourceDialog() {
    // En web, solo mostramos la opción de galería
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }

    // En móvil, mostramos ambas opciones
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.blue),
                title: MyText(LocaleKeys.takePhoto),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: MyText(LocaleKeys.selectFromGallery),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: MyText(LocaleKeys.cancel),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    // Prioridad: imagen local > imagen web > imagen URL > placeholder
    if (!kIsWeb && _selectedImage != null) {
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    } else if (kIsWeb && _webImage != null) {
      return ClipOval(
        child: Image.memory(
          _webImage!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    } else if (widget.currentAvatarUrl != null &&
        widget.currentAvatarUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.currentAvatarUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
          // Add unique key based on URL to force refresh on URL change
          key: ValueKey(widget.currentAvatarUrl),
        ),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          // Avatar circular
          _buildAvatarImage(),

          // Loading overlay
          if (widget.isLoading)
            Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),

          // Botón de editar (overlay con icono de cámara)
          if (!widget.isLoading)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
