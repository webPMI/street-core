// lib/core/media/widgets/lazy_media_gallery.dart

import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import 'cached_media_image.dart';
import 'zoomable_image_preview.dart';

/// Lazy loading media gallery with performance optimizations
///
/// Features:
/// - Lazy loading (loads images as you scroll)
/// - Memory efficient (caches only visible items)
/// - Tap to zoom preview
/// - Grid or list layout
/// - Customizable spacing
class LazyMediaGallery extends StatefulWidget {
  const LazyMediaGallery({
    super.key,
    required this.imageUrls,
    this.columns = 3,
    this.aspectRatio = 1.0,
    this.spacing = 8.0,
    this.onImageTap,
    this.heroTagPrefix,
    this.maxCrossAxisExtent = 150.0,
  });

  /// List of image URLs
  final List<String> imageUrls;

  /// Number of columns (for grid)
  final int columns;

  /// Aspect ratio of each item
  final double aspectRatio;

  /// Spacing between items
  final double spacing;

  /// Callback when image is tapped
  final void Function(int index, String url)? onImageTap;

  /// Hero tag prefix for animations
  final String? heroTagPrefix;

  /// Max cross axis extent for grid items
  final double maxCrossAxisExtent;

  @override
  State<LazyMediaGallery> createState() => _LazyMediaGalleryState();
}

class _LazyMediaGalleryState extends State<LazyMediaGallery> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleImageTap(int index, String url) {
    if (widget.onImageTap != null) {
      widget.onImageTap!(index, url);
    } else {
      // Default: open zoom preview
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: ZoomableImagePreview(
                imageUrl: url,
                heroTag: widget.heroTagPrefix != null
                    ? '${widget.heroTagPrefix}_$index'
                    : null,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(widget.spacing),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: widget.maxCrossAxisExtent,
        mainAxisSpacing: widget.spacing,
        crossAxisSpacing: widget.spacing,
        childAspectRatio: widget.aspectRatio,
      ),
      // Set cacheExtent to load items slightly before they're visible
      cacheExtent: 500,
      itemCount: widget.imageUrls.length,
      itemBuilder: (context, index) {
        return _buildGridItem(index);
      },
    );
  }

  Widget _buildGridItem(int index) {
    final url = widget.imageUrls[index];
    final heroTag = widget.heroTagPrefix != null
        ? '${widget.heroTagPrefix}_$index'
        : null;

    Widget image = CachedThumbnailImage(
      imageUrl: url,
      size: widget.maxCrossAxisExtent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => _handleImageTap(index, url),
    );

    // Wrap with Hero if tag provided
    if (heroTag != null) {
      return Hero(
        tag: heroTag,
        child: image,
      );
    }

    return image;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No images',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal scrolling media carousel
class LazyMediaCarousel extends StatelessWidget {
  const LazyMediaCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200.0,
    this.aspectRatio = 16 / 9,
    this.spacing = 8.0,
    this.onImageTap,
    this.heroTagPrefix,
  });

  final List<String> imageUrls;
  final double height;
  final double aspectRatio;
  final double spacing;
  final void Function(int index, String url)? onImageTap;
  final String? heroTagPrefix;

  void _handleImageTap(BuildContext context, int index, String url) {
    if (onImageTap != null) {
      onImageTap!(index, url);
    } else {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: ZoomableImagePreview(
                imageUrl: url,
                heroTag: heroTagPrefix != null
                    ? '${heroTagPrefix}_$index'
                    : null,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No images',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: spacing),
        cacheExtent: 500,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          final url = imageUrls[index];
          final heroTag = heroTagPrefix != null
              ? '${heroTagPrefix}_$index'
              : null;

          Widget image = CachedMediaImage(
            imageUrl: url,
            width: height * aspectRatio,
            height: height,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(AppRadius.md),
            memCacheWidth: (height * aspectRatio * 2).toInt(),
            memCacheHeight: (height * 2).toInt(),
          );

          if (heroTag != null) {
            image = Hero(tag: heroTag, child: image);
          }

          return Padding(
            padding: EdgeInsets.only(
              right: index < imageUrls.length - 1 ? spacing : 0,
            ),
            child: InkWell(
              onTap: () => _handleImageTap(context, index, url),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: image,
            ),
          );
        },
      ),
    );
  }
}
