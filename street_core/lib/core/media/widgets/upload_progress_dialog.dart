// lib/core/media/widgets/upload_progress_dialog.dart

import '../../helpers/logger.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/my_text.dart';
import 'package:flutter/material.dart';

/// Professional upload progress dialog
///
/// Shows progress with visual feedback, percentage, and optional cancel button
///
/// Example usage:
/// ```dart
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (context) => UploadProgressDialog(
///     progress: 0.5,
///     message: 'Uploading images...',
///     onCancel: () {
///       // Cancel upload logic
///       Navigator.pop(context);
///     },
///   ),
/// );
/// ```
class UploadProgressDialog extends StatelessWidget {

  const UploadProgressDialog({
    super.key,
    required this.progress,
    this.messageKey = 'uploading',
    this.onCancel,
    this.fileInfo,
  });
  /// Progress value from 0.0 to 1.0
  final double progress;

  /// Message key for translation
  final String messageKey;

  /// Optional cancel callback
  final VoidCallback? onCancel;

  /// Show file count
  final String? fileInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress icon
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: AppIconSize.xl,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Message
          MyText(
            messageKey,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          if (fileInfo != null) ...[
            SizedBox(height: AppSpacing.sm),
            MyText(
              fileInfo!,
              noTranslation: true,
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: AppSpacing.lg),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Percentage
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
      actions: onCancel != null
          ? [
              TextButton(
                onPressed: () {
                  AppLogger.info(
                    'Upload cancelled by user',
                    tag: 'UploadProgressDialog',
                  );
                  onCancel!();
                },
                child: const MyText('cancel'),
              ),
            ]
          : null,
    );
  }
}

/// Compact upload progress indicator for inline use
///
/// Example usage:
/// ```dart
/// UploadProgressIndicator(
///   progress: 0.7,
///   filename: 'image.jpg',
/// )
/// ```
class UploadProgressIndicator extends StatelessWidget {
  const UploadProgressIndicator({
    super.key,
    required this.progress,
    this.filename,
  });

  final double progress;
  final String? filename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: AppIconSize.sm,
                  color: colorScheme.primary,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: filename != null
                      ? Text(
                          filename!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        )
                      : const MyText('uploading', fontWeight: FontWeight.w500),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Success dialog after upload completes
class UploadSuccessDialog extends StatelessWidget {
  const UploadSuccessDialog({
    super.key,
    this.messageKey = 'upload_complete',
    this.fileCount = 1,
    this.onDone,
  });

  static const String _tag = 'UploadSuccessDialog';

  final String messageKey;
  final int fileCount;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    AppLogger.info(
      'Upload completed successfully: $fileCount files',
      tag: _tag,
    );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use semantic success colors from theme
    final successColor = colorScheme.brightness == Brightness.dark
        ? const Color(0xFF81C784)
        : const Color(0xFF2E7D32);
    final successBgColor = colorScheme.brightness == Brightness.dark
        ? successColor.withValues(alpha: 0.2)
        : successColor.withValues(alpha: 0.1);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: successBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: AppIconSize.xl,
              color: successColor,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          MyText(
            messageKey,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          MyText(
            'files_uploaded_successfully',
            args: {'count': fileCount.toString()},
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDone?.call();
          },
          child: const MyText('done'),
        ),
      ],
    );
  }
}

/// Error dialog after upload fails
class UploadErrorDialog extends StatelessWidget {
  const UploadErrorDialog({
    super.key,
    this.messageKey = 'upload_failed',
    this.details,
    this.onRetry,
    this.onCancel,
  });

  static const String _tag = 'UploadErrorDialog';

  final String messageKey;
  final String? details;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    AppLogger.error('Upload failed: $messageKey', tag: _tag);
    if (details != null) {
      AppLogger.debug('Error details: $details', tag: _tag);
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: AppIconSize.xl,
              color: colorScheme.onErrorContainer,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          MyText(
            messageKey,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
          if (details != null) ...[
            SizedBox(height: AppSpacing.sm),
            MyText(
              details!,
              noTranslation: true,
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: () {
              AppLogger.debug('User cancelled after error', tag: _tag);
              Navigator.pop(context);
              onCancel?.call();
            },
            child: const MyText('cancel'),
          ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              AppLogger.info('User retrying upload', tag: _tag);
              Navigator.pop(context);
              onRetry?.call();
            },
            child: const MyText('retry'),
          ),
      ],
    );
  }
}
