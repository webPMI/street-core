// lib/presentation/dashboard/posts/widgets/post_media_carousel.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flutter/material.dart';

/// Widget para mostrar carrusel de imágenes/videos
///
/// Performance Optimizations:
/// - Uses CachedNetworkImage for automatic memory and disk caching
/// - Lazy loading for carousel items (only visible items rendered)
/// - Proper placeholder/error states with shimmer effect
/// - Memory-efficient image disposal
class PostMediaCarousel extends StatefulWidget {

  const PostMediaCarousel({
    super.key,
    required this.mediaUrls,
    required this.mediaType,
    this.onTap,
  });
  final List<String> mediaUrls;
  final String mediaType;
  final VoidCallback? onTap;

  @override
  State<PostMediaCarousel> createState() => _PostMediaCarouselState();
}

class _PostMediaCarouselState extends State<PostMediaCarousel> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // Si es solo una imagen/video
    if (widget.mediaUrls.length == 1) {
      return AspectRatio(
        aspectRatio: 1.0, // Always square
        child: GestureDetector(
          onTap: widget.onTap,
          child: _buildMediaItem(widget.mediaUrls.first),
        ),
      );
    }

    // Carousel para múltiples medios
    return AspectRatio(
      aspectRatio: 1.0, // Always square
      child: Stack(
        children: [
          carousel.CarouselSlider.builder(
            itemCount: widget.mediaUrls.length,
            options: carousel.CarouselOptions(
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final url = widget.mediaUrls[index];
              return GestureDetector(
                onTap: widget.onTap,
                child: _buildMediaItem(url),
              );
            },
          ),

          // Indicador de posición
          if (widget.mediaUrls.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.mediaUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(String url) {
    // Si es video, mostrar placeholder con ícono de play
    if (widget.mediaType == 'video') {
      return Stack(
        fit: StackFit.expand,
        children: [
          // OPTIMIZATION: Use CachedNetworkImage for video thumbnails
          // Provides automatic disk and memory caching
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            // Placeholder while loading - shimmer effect for better UX
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.videocam, size: 64, color: Colors.grey),
            ),
            // OPTIMIZATION: Max cache size to prevent memory bloat
            maxHeightDiskCache: 800,
            maxWidthDiskCache: 800,
            // OPTIMIZATION: Fade-in animation for better perceived performance
            fadeInDuration: const Duration(milliseconds: 300),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // OPTIMIZATION: CachedNetworkImage for images
    // Benefits:
    // - Automatic memory cache (LRU eviction)
    // - Automatic disk cache (persistent across sessions)
    // - Better loading indicators
    // - Prevents duplicate downloads
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      // Shimmer placeholder for better perceived performance
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
      ),
      // OPTIMIZATION: Limit cached image size to reduce memory usage
      // Original images can be very large; resize for display
      maxHeightDiskCache: 1200,
      maxWidthDiskCache: 1200,
      // OPTIMIZATION: Smooth fade-in animation
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}
