// lib/core/media/widgets/cached_media_image.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_spacing.dart';

/// Optimized cached network image with loading states
///
/// Features:
/// - Automatic caching
/// - Shimmer loading effect
/// - Error handling with retry
/// - Memory optimization
/// - Placeholder support
class CachedMediaImage extends StatelessWidget {
  const CachedMediaImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.memCacheWidth,
    this.memCacheHeight,
  });

  /// Image URL
  final String imageUrl;

  /// Width
  final double? width;

  /// Height
  final double? height;

  /// Box fit
  final BoxFit fit;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Custom placeholder
  final Widget? placeholder;

  /// Custom error widget
  final Widget? errorWidget;

  /// Fade in duration
  final Duration fadeInDuration;

  /// Memory cache width (for optimization)
  final int? memCacheWidth;

  /// Memory cache height (for optimization)
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: fadeInDuration,
      placeholder: (context, url) =>
          placeholder ?? _buildShimmerPlaceholder(theme),
      errorWidget: (context, url, error) =>
          errorWidget ?? _buildErrorWidget(theme, context),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildShimmerPlaceholder(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerHighest,
      highlightColor: theme.colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        color: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cached avatar image (circular)
class CachedAvatarImage extends StatelessWidget {
  const CachedAvatarImage({
    super.key,
    required this.imageUrl,
    this.size = 40.0,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double size;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return CachedMediaImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      memCacheWidth: (size * 2).toInt(),
      memCacheHeight: (size * 2).toInt(),
      placeholder: placeholder,
      errorWidget: errorWidget ??
          CircleAvatar(
            radius: size / 2,
            child: Icon(Icons.person, size: size * 0.6),
          ),
    );
  }
}

/// Cached thumbnail image (optimized for small sizes)
class CachedThumbnailImage extends StatelessWidget {
  const CachedThumbnailImage({
    super.key,
    required this.imageUrl,
    this.size = 80.0,
    this.borderRadius,
    this.onTap,
  });

  final String imageUrl;
  final double size;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget image = CachedMediaImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.sm),
      // Optimize memory by limiting cache size to 2x actual size
      memCacheWidth: (size * 2).toInt(),
      memCacheHeight: (size * 2).toInt(),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.sm),
        child: image,
      );
    }

    return image;
  }
}
