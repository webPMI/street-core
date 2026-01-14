// lib/core/media/widgets/media_upload_feedback.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../lang/locale_keys.dart';
import '../bloc/media_upload_cubit.dart';
import '../bloc/media_upload_state.dart';
import '../../theme/app_spacing.dart';
import '../../lang/context_tr.dart';
import 'animated_upload_progress.dart';

/// Enhanced media upload feedback with visual states
///
/// Features:
/// - Real-time progress updates
/// - Success/error animations
/// - Auto-dismiss on success
/// - Retry on error
/// - Cancel support
class MediaUploadFeedback extends StatelessWidget {
  const MediaUploadFeedback({
    super.key,
    this.fileName,
    this.autoDismissOnSuccess = true,
    this.dismissDelay = const Duration(seconds: 2),
    this.onRetry,
    this.onCancel,
  });

  final String? fileName;
  final bool autoDismissOnSuccess;
  final Duration dismissDelay;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MediaUploadCubit, MediaUploadState>(
      listener: (context, state) {
        if (state is MediaUploadSuccess && autoDismissOnSuccess) {
          Future.delayed(dismissDelay, () {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      },
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, MediaUploadState state) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress indicator
          _buildProgressIndicator(state),

          SizedBox(height: AppSpacing.lg),

          // Status message
          _buildStatusMessage(context, state, theme),

          // Action buttons
          if (state is MediaUploadError || state is MediaUploadLoading)
            ..._buildActionButtons(context, state),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(MediaUploadState state) {
    double progress = 0.0;
    UploadStatus status = UploadStatus.uploading;

    if (state is MediaUploadLoading) {
      progress = state.progress;
      status = UploadStatus.uploading;
    } else if (state is MediaUploadSuccess) {
      progress = 1.0;
      status = UploadStatus.success;
    } else if (state is MediaUploadError) {
      progress = 0.0;
      status = UploadStatus.error;
    }

    return AnimatedUploadProgress(
      progress: progress,
      status: status,
      fileName: fileName,
      showFileName: true,
    );
  }

  Widget _buildStatusMessage(
    BuildContext context,
    MediaUploadState state,
    ThemeData theme,
  ) {
    String message;
    Color? messageColor;

    if (state is MediaUploadLoading) {
      message = state.fileName != null
          ? context.tr(LocaleKeys.mediaUploadUploadingFiles)
          : context.tr(LocaleKeys.mediaUploadUploading);
      messageColor = theme.colorScheme.onSurface;
    } else if (state is MediaUploadSuccess) {
      message = context.tr(LocaleKeys.mediaUploadSuccess);
      messageColor = theme.colorScheme.primary;
    } else if (state is MediaUploadError) {
      message = state.errorMessage;
      messageColor = theme.colorScheme.error;
    } else {
      message = context.tr(LocaleKeys.mediaUploadProcessing);
      messageColor = theme.colorScheme.onSurfaceVariant;
    }

    return Text(
      message,
      style: TextStyle(
        fontSize: 14,
        color: messageColor,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<Widget> _buildActionButtons(
    BuildContext context,
    MediaUploadState state,
  ) {
    return [
      SizedBox(height: AppSpacing.md),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cancel/Close button
          if (state is MediaUploadLoading)
            TextButton.icon(
              onPressed: onCancel ??
                  () {
                    context.read<MediaUploadCubit>().cancelUpload();
                    Navigator.of(context).pop();
                  },
              icon: const Icon(Icons.close),
              label: Text(context.tr(LocaleKeys.mediaActionCancel)),
            ),

          // Retry button (on error)
          if (state is MediaUploadError)
            ElevatedButton.icon(
              onPressed: onRetry ?? () => Navigator.of(context).pop(),
              icon: const Icon(Icons.refresh),
              label: Text(context.tr(LocaleKeys.mediaActionRetry)),
            ),

          // Close button (on error)
          if (state is MediaUploadError)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr(LocaleKeys.mediaActionCancel)),
            ),
        ],
      ),
    ];
  }
}

/// Floating upload feedback (less intrusive)
class FloatingUploadFeedback extends StatelessWidget {
  const FloatingUploadFeedback({
    super.key,
    this.fileName,
  });

  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaUploadCubit, MediaUploadState>(
      builder: (context, state) {
        if (state is MediaUploadInitial || state is MediaUploadSuccess) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: AppSpacing.lg,
          left: AppSpacing.md,
          right: AppSpacing.md,
          child: _buildFloatingCard(context, state),
        );
      },
    );
  }

  Widget _buildFloatingCard(BuildContext context, MediaUploadState state) {
    final theme = Theme.of(context);

    Color backgroundColor;
    IconData icon;
    String message;

    if (state is MediaUploadLoading) {
      backgroundColor = theme.colorScheme.primaryContainer;
      icon = Icons.cloud_upload_outlined;
      message = fileName != null
          ? ' ${context.tr(LocaleKeys.mediaUploadUploadingFiles)} $fileName...'
          : context.tr(LocaleKeys.mediaUploadUploading);
    } else if (state is MediaUploadError) {
      backgroundColor = theme.colorScheme.errorContainer;
      icon = Icons.error_outline;
      message = state.errorMessage;
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      icon = Icons.info_outline;
      message = context.tr(LocaleKeys.mediaUploadProcessing);
    }

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(AppRadius.md),
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Icon
            Icon(icon, size: 24),

            SizedBox(width: AppSpacing.sm),

            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (state is MediaUploadLoading) ...[
                    SizedBox(height: AppSpacing.xs),
                    LinearProgressIndicator(
                      value: state.progress,
                      backgroundColor: theme.colorScheme.surface,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(width: AppSpacing.sm),

            // Close button
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                if (state is MediaUploadLoading) {
                  context.read<MediaUploadCubit>().cancelUpload();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
