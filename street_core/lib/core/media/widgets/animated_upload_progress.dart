// lib/core/media/widgets/animated_upload_progress.dart

import 'package:flutter/material.dart';
import '../../lang/locale_keys.dart';
import '../../theme/app_spacing.dart';
import '../../lang/context_tr.dart';

/// Animated upload progress indicator with smooth transitions
///
/// Features:
/// - Smooth progress animation
/// - Pulsing effect while uploading
/// - Success/error states with icons
/// - Customizable colors and size
class AnimatedUploadProgress extends StatefulWidget {
  const AnimatedUploadProgress({
    super.key,
    required this.progress,
    this.status = UploadStatus.uploading,
    this.fileName,
    this.size = 120.0,
    this.strokeWidth = 8.0,
    this.showPercentage = true,
    this.showFileName = true,
  });

  /// Progress from 0.0 to 1.0
  final double progress;

  /// Current upload status
  final UploadStatus status;

  /// File name to display
  final String? fileName;

  /// Size of the progress circle
  final double size;

  /// Width of the progress stroke
  final double strokeWidth;

  /// Show percentage text
  final bool showPercentage;

  /// Show file name below
  final bool showFileName;

  @override
  State<AnimatedUploadProgress> createState() => _AnimatedUploadProgressState();
}

class _AnimatedUploadProgressState extends State<AnimatedUploadProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress circle
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ProgressBackgroundPainter(
                  color: theme.colorScheme.surfaceContainerHighest,
                  strokeWidth: widget.strokeWidth,
                ),
              ),

              // Animated progress
              if (widget.status == UploadStatus.uploading)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: widget.progress,
                    ),
                    builder: (context, value, _) => CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _ProgressPainter(
                        progress: value,
                        color: theme.colorScheme.primary,
                        strokeWidth: widget.strokeWidth,
                      ),
                    ),
                  ),
                ),

              // Success/Error overlay
              if (widget.status != UploadStatus.uploading)
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: widget.size * 0.6,
                    height: widget.size * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(theme),
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: Colors.white,
                      size: widget.size * 0.35,
                    ),
                  ),
                ),

              // Percentage text (only while uploading)
              if (widget.showPercentage &&
                  widget.status == UploadStatus.uploading)
                Text(
                  '${(widget.progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: widget.size * 0.18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
            ],
          ),
        ),

        // Status message
        if (widget.status != UploadStatus.uploading) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            _getStatusMessage(context),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(theme),
            ),
          ),
        ],

        // File name
        if (widget.showFileName && widget.fileName != null) ...[
          SizedBox(height: AppSpacing.xs),
          Text(
            widget.fileName!,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(ThemeData theme) {
    switch (widget.status) {
      case UploadStatus.success:
        return theme.colorScheme.primary;
      case UploadStatus.error:
        return theme.colorScheme.error;
      case UploadStatus.uploading:
        return theme.colorScheme.primary;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.status) {
      case UploadStatus.success:
        return Icons.check_rounded;
      case UploadStatus.error:
        return Icons.close_rounded;
      case UploadStatus.uploading:
        return Icons.upload_rounded;
    }
  }

  String _getStatusMessage(BuildContext context) {
    switch (widget.status) {
      case UploadStatus.success:
        return context.tr( LocaleKeys.mediaUploadSuccess);
      case UploadStatus.error:
        return context.tr(LocaleKeys.mediaUploadFailed);
      case UploadStatus.uploading:
        return context.tr(LocaleKeys.mediaUploadUploading);
    }
  }
}

/// Custom painter for progress background
class _ProgressBackgroundPainter extends CustomPainter {
  _ProgressBackgroundPainter({
    required this.color,
    required this.strokeWidth,
  });

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_ProgressBackgroundPainter oldDelegate) =>
      color != oldDelegate.color || strokeWidth != oldDelegate.strokeWidth;
}

/// Custom painter for animated progress
class _ProgressPainter extends CustomPainter {
  _ProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = -90 * 3.14159 / 180; // Start from top
    final sweepAngle = 2 * 3.14159 * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth;
}

/// Upload status enum
enum UploadStatus {
  uploading,
  success,
  error,
}
