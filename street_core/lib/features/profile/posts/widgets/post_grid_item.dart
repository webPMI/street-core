// lib/presentation/dashboard/posts/widgets/post_grid_item.dart

import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/widgets/my_text.dart';
import '../../models/post_model.dart';
import 'package:flutter/material.dart';

/// Grid item widget for displaying a post thumbnail
class PostGridItem extends StatelessWidget {
  const PostGridItem({super.key, required this.post, this.onTap});
  final PostModel post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Post thumbnail or placeholder
            _buildThumbnail(context),

            // Media type indicator (video/carousel)
            if (post.isVideo || post.isCarousel)
              Positioned(top: 8, right: 8, child: _buildMediaTypeIndicator()),

            // Engagement overlay (likes count)
            if (post.likesCount > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildEngagementOverlay(context),
              ),
          ],
        ),
      ),
    );
  }

  /// Build thumbnail image
  Widget _buildThumbnail(BuildContext context) {
    if (post.hasMedia && post.mediaUrls.isNotEmpty) {
      // Use thumbnail for videos, first media URL for images
      final imageUrl = post.isVideo && post.thumbnailUrl != null
          ? post.thumbnailUrl!
          : post.mediaUrls.first;

      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error_outline, color: Colors.grey),
          ),
        ),
      );
    } else {
      // Text-only post - show caption preview
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: MyText(
            post.caption,
            maxLines: 4,
            fontSize: 12,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  /// Build media type indicator (video/carousel icon)
  Widget _buildMediaTypeIndicator() {
    IconData icon;
    if (post.isVideo) {
      icon = Icons.play_circle_outline;
    } else if (post.isCarousel) {
      icon = Icons.collections;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  /// Build engagement overlay showing likes count
  Widget _buildEngagementOverlay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            _formatCount(post.likesCount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Format count for display (1000 -> 1K, 1000000 -> 1M)
  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    } else {
      return count.toString();
    }
  }
}
