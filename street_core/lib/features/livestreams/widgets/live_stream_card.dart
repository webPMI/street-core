// lib/features/livestreams/widgets/live_stream_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:street_core/core/theme/app_spacing.dart';
import 'package:street_core/features/livestreams/models/models.dart';
import 'package:street_core/features/livestreams/widgets/live_badge.dart';

/// Reusable LiveStream card widget
///
/// Supports both grid and list layouts.
///
/// Usage:
/// ```dart
/// LiveStreamCard(
///   stream: myStream,
///   onTap: () => navigateToStream(),
/// )
///
/// LiveStreamCard.list(
///   stream: myStream,
///   onTap: () => navigateToStream(),
/// )
/// ```
class LiveStreamCard extends StatelessWidget {
  final LiveStream stream;
  final VoidCallback? onTap;
  final bool isListLayout;
  final bool showHostInfo;
  final bool showStats;

  const LiveStreamCard({
    super.key,
    required this.stream,
    this.onTap,
    this.isListLayout = false,
    this.showHostInfo = true,
    this.showStats = true,
  });

  /// List layout variant
  const LiveStreamCard.list({
    super.key,
    required this.stream,
    this.onTap,
    this.showHostInfo = true,
    this.showStats = true,
  }) : isListLayout = true;

  /// Grid layout variant
  const LiveStreamCard.grid({
    super.key,
    required this.stream,
    this.onTap,
    this.showHostInfo = true,
    this.showStats = true,
  }) : isListLayout = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: isListLayout ? _buildListLayout(context) : _buildGridLayout(context),
      ),
    );
  }

  Widget _buildGridLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        _buildThumbnail(context, aspectRatio: 16 / 9),

        // Info
        Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                stream.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (showHostInfo) ...[
                SizedBox(height: AppSpacing.xs),
                // Host name
                Text(
                  stream.hostName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              if (showStats) ...[
                SizedBox(height: AppSpacing.xs),
                // Stats row
                _buildStatsRow(context),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        SizedBox(
          width: 120,
          height: 90,
          child: _buildThumbnail(context, aspectRatio: 4 / 3),
        ),

        // Info
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  stream.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (showHostInfo) ...[
                  SizedBox(height: AppSpacing.xs),
                  // Host name
                  Text(
                    stream.hostName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                if (showStats) ...[
                  SizedBox(height: AppSpacing.xs),
                  // Stats row
                  _buildStatsRow(context),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(BuildContext context, {required double aspectRatio}) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          if (stream.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: stream.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => _buildPlaceholder(context),
            )
          else
            _buildPlaceholder(context),

          // Gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Status badge
          Positioned(
            top: AppSpacing.xs,
            left: AppSpacing.xs,
            child: _buildStatusBadge(),
          ),

          // Viewer count (if live)
          if (stream.isLive)
            Positioned(
              bottom: AppSpacing.xs,
              left: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatNumber(stream.viewerCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Duration (if ended)
          if (stream.isEnded && stream.durationSeconds != null)
            Positioned(
              bottom: AppSpacing.xs,
              right: AppSpacing.xs,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stream.durationFormatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.videocam,
        size: 48,
        color: Colors.grey[500],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (stream.isLive) {
      return const LiveBadge(size: BadgeSize.small);
    }

    if (stream.isScheduled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'PROGRAMADO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (stream.isEnded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'FINALIZADO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        // Viewers/Views
        Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          _formatNumber(stream.isLive ? stream.viewerCount : stream.totalViews),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),

        const SizedBox(width: 12),

        // Reactions
        Icon(Icons.favorite, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          _formatNumber(stream.reactionCount),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),

        const SizedBox(width: 12),

        // Messages
        Icon(Icons.chat_bubble, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          _formatNumber(stream.messageCount),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
