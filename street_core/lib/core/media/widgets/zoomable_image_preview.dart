// lib/core/media/widgets/zoomable_image_preview.dart

import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';

import '../../lang/context_tr.dart';
import '../../lang/locale_keys.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/my_text.dart';

/// Zoomable image preview with gestures
///
/// Features:
/// - Pinch to zoom (2x - 4x)
/// - Double tap to zoom
/// - Pan when zoomed
/// - Smooth animations
/// - Loading states
/// - Error handling
class ZoomableImagePreview extends StatefulWidget {
  const ZoomableImagePreview({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.imageBytes,
    this.heroTag,
    this.onClose,
    this.minScale = 1.0,
    this.maxScale = 4.0,
    this.doubleTapScale = 2.0,
  });

  /// Network image URL
  final String? imageUrl;

  /// Local file
  final File? imageFile;

  /// Image bytes (for web)
  final Uint8List? imageBytes;

  /// Hero animation tag
  final String? heroTag;

  /// Close callback
  final VoidCallback? onClose;

  /// Minimum scale
  final double minScale;

  /// Maximum scale
  final double maxScale;

  /// Scale on double tap
  final double doubleTapScale;

  @override
  State<ZoomableImagePreview> createState() => _ZoomableImagePreviewState();
}

class _ZoomableImagePreviewState extends State<ZoomableImagePreview>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_doubleTapDetails == null) return;

    final position = _doubleTapDetails!.localPosition;
    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    final newScale = currentScale > widget.minScale
        ? widget.minScale
        : widget.doubleTapScale;

    final zooming = newScale > currentScale;

    Matrix4 newMatrix;
    if (zooming) {
      // Zoom in to tap position
      newMatrix = Matrix4.identity()
        ..translate(
          -position.dx * (newScale - 1),
          -position.dy * (newScale - 1),
        )
        ..scale(newScale);
    } else {
      // Zoom out to center
      newMatrix = Matrix4.identity();
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: newMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Zoomable image
          Center(
            child: GestureDetector(
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: widget.minScale,
                maxScale: widget.maxScale,
                child: _buildImage(),
              ),
            ),
          ),

          // Close button
          SafeArea(
            child: Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onClose ?? () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Zoom hint (appears briefly)
          Positioned(
            bottom: AppSpacing.xl,
            left: 0,
            right: 0,
            child: _ZoomHint(),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final heroTag = widget.heroTag;

    Widget imageWidget;

    if (widget.imageUrl != null) {
      // Network image with cache
      imageWidget = CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    } else if (widget.imageFile != null) {
      // Local file
      imageWidget = Image.file(
        widget.imageFile!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (widget.imageBytes != null) {
      // Bytes (web)
      imageWidget = Image.memory(
        widget.imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      return _buildErrorWidget();
    }

    // Wrap with Hero if tag provided
    if (heroTag != null) {
      return Hero(
        tag: heroTag,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            context.tr(LocaleKeys.mediaErrorUnknown),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Zoom hint that appears briefly
class _ZoomHint extends StatefulWidget {
  @override
  State<_ZoomHint> createState() => _ZoomHintState();
}

class _ZoomHintState extends State<_ZoomHint> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    // Hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _visible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pinch_outlined,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: AppSpacing.xs),
              const MyText(
                LocaleKeys.pinchToZoom,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
