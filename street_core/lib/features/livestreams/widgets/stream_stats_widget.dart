// lib/features/livestreams/widgets/stream_stats_widget.dart

import 'package:flutter/material.dart';
import 'package:street_core/core/theme/app_spacing.dart';
import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/features/livestreams/models/models.dart';

/// Reusable stream statistics widget
///
/// Usage:
/// ```dart
/// StreamStatsWidget(
///   viewerCount: 1234,
///   duration: Duration(minutes: 45),
/// )
///
/// StreamStatsWidget.fromStream(stream: liveStream)
/// ```
class StreamStatsWidget extends StatelessWidget {
  final int viewerCount;
  final int? peakViewers;
  final int? totalViews;
  final int? reactionCount;
  final int? messageCount;
  final Duration? duration;
  final bool isCompact;
  final Axis direction;

  const StreamStatsWidget({
    super.key,
    required this.viewerCount,
    this.peakViewers,
    this.totalViews,
    this.reactionCount,
    this.messageCount,
    this.duration,
    this.isCompact = false,
    this.direction = Axis.horizontal,
  });

  /// Create from LiveStream
  factory StreamStatsWidget.fromStream({
    required LiveStream stream,
    bool isCompact = false,
    Axis direction = Axis.horizontal,
  }) {
    return StreamStatsWidget(
      viewerCount: stream.viewerCount,
      peakViewers: stream.peakViewers,
      totalViews: stream.totalViews,
      reactionCount: stream.reactionCount,
      messageCount: stream.messageCount,
      duration: stream.durationSeconds != null
          ? Duration(seconds: stream.durationSeconds!)
          : null,
      isCompact: isCompact,
      direction: direction,
    );
  }

  /// Create from StreamStats
  factory StreamStatsWidget.fromStats({
    required StreamStats stats,
    bool isCompact = false,
    Axis direction = Axis.horizontal,
  }) {
    return StreamStatsWidget(
      viewerCount: stats.currentViewers,
      peakViewers: stats.peakViewers,
      totalViews: stats.totalViews,
      reactionCount: stats.reactionCount,
      messageCount: stats.messageCount,
      duration: Duration(seconds: stats.duration),
      isCompact: isCompact,
      direction: direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      // Viewers
      _StatItem(
        icon: Icons.visibility,
        value: _formatNumber(viewerCount),
        label: isCompact ? null : context.tr(LocaleKeys.viewers),
      ),

      // Peak viewers
      if (peakViewers != null && peakViewers! > 0)
        _StatItem(
          icon: Icons.trending_up,
          value: _formatNumber(peakViewers!),
          label: isCompact ? null : context.tr(LocaleKeys.peak),
        ),

      // Total views
      if (totalViews != null && totalViews! > 0)
        _StatItem(
          icon: Icons.remove_red_eye,
          value: _formatNumber(totalViews!),
          label: isCompact ? null : context.tr(LocaleKeys.views),
        ),

      // Reactions
      if (reactionCount != null && reactionCount! > 0)
        _StatItem(
          icon: Icons.favorite,
          value: _formatNumber(reactionCount!),
          label: isCompact ? null : context.tr(LocaleKeys.reactions),
        ),

      // Messages
      if (messageCount != null && messageCount! > 0)
        _StatItem(
          icon: Icons.chat_bubble,
          value: _formatNumber(messageCount!),
          label: isCompact ? null : context.tr(LocaleKeys.messages),
        ),

      // Duration
      if (duration != null)
        _StatItem(
          icon: Icons.access_time,
          value: _formatDuration(duration!),
          label: isCompact ? null : context.tr(LocaleKeys.duration),
        ),
    ];

    if (direction == Axis.horizontal) {
      return Wrap(
        spacing: isCompact ? AppSpacing.sm : AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: items,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _intersperse(
        items,
        SizedBox(height: AppSpacing.xs),
      ),
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  List<Widget> _intersperse(List<Widget> widgets, Widget separator) {
    if (widgets.isEmpty) return [];

    final result = <Widget>[widgets.first];
    for (var i = 1; i < widgets.length; i++) {
      result.add(separator);
      result.add(widgets[i]);
    }
    return result;
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;

  const _StatItem({
    required this.icon,
    required this.value,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      // Compact mode
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
          ),
        ],
      );
    }

    // Full mode with label
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            label!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
      ],
    );
  }
}

/// Overlay stats widget for video player
///
/// Shows stats as an overlay on the video
///
/// Usage:
/// ```dart
/// StreamStatsOverlay(
///   viewerCount: 1234,
///   duration: Duration(minutes: 45),
///   position: OverlayPosition.topRight,
/// )
/// ```
class StreamStatsOverlay extends StatelessWidget {
  final int viewerCount;
  final Duration? duration;
  final OverlayPosition position;
  final Color? backgroundColor;

  const StreamStatsOverlay({
    super.key,
    required this.viewerCount,
    this.duration,
    this.position = OverlayPosition.topRight,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? Colors.black.withValues(alpha: 0.7);

    return Positioned(
      top: position.isTop ? AppSpacing.sm : null,
      bottom: position.isBottom ? AppSpacing.sm : null,
      left: position.isLeft ? AppSpacing.sm : null,
      right: position.isRight ? AppSpacing.sm : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Viewer count
            const Icon(Icons.visibility, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              _formatNumber(viewerCount),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            // Duration
            if (duration != null) ...[
              const SizedBox(width: 12),
              const Icon(Icons.access_time, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                _formatDuration(duration!),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

enum OverlayPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  bool get isTop => this == topLeft || this == topRight;
  bool get isBottom => this == bottomLeft || this == bottomRight;
  bool get isLeft => this == topLeft || this == bottomLeft;
  bool get isRight => this == topRight || this == bottomRight;
}
