// lib/features/profile/widgets/profile_image.dart

import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:street_core/core/lang/locale_keys.dart';

import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/widgets/my_text.dart';

/// Widget for displaying and uploading profile image
/// Shows current image or placeholder, allows upload/change with preview
class ProfileImage extends StatefulWidget {
  const ProfileImage({
    this.currentImageUrl,
    this.onImageSelected,
    this.size = 120.0,
    this.editable = true,
    super.key,
  });

  final String? currentImageUrl;
  final Function(File)? onImageSelected;
  final double size;
  final bool editable;

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (!mounted) return;
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        // Call callback if provided
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(_selectedImage!);
        }
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        SnackBarHelper.showError(context, 'error.picking.image');
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: MyText(LocaleKeys.takePhoto),
              onTap: () {
                Navigator.pop(modalContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: MyText(LocaleKeys.chooseFromGallery),
              onTap: () {
                Navigator.pop(modalContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (widget.currentImageUrl != null || _selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: MyText(
                  LocaleKeys.removePhoto,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(modalContext);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.primaryColor, width: 3.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(child: _buildImage(theme)),
        ),
        if (widget.editable)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                width: widget.size * 0.3,
                height: widget.size * 0.3,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2.0,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: widget.size * 0.15,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage(ThemeData theme) {
    // Show selected image first (preview)
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    }

    // Show current image from URL
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return Image.network(
        widget.currentImageUrl!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(theme);
        },
      );
    }

    // Show placeholder
    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      width: widget.size,
      height: widget.size,
      color: Colors.grey.shade300,
      child: Icon(
        Icons.person,
        size: widget.size * 0.6,
        color: Colors.grey.shade600,
      ),
    );
  }
}
