// lib/features/competitions/widgets/sync_status_indicator.dart

import 'package:flutter/material.dart';
import '../services/offline_sync_service.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';

/// Widget that shows offline sync status
class SyncStatusIndicator extends StatelessWidget {
  final OfflineSyncService syncService;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    required this.syncService,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: syncService.syncStatus,
      initialData: SyncStatus(
        isSyncing: syncService.isSyncing,
        pendingCount: syncService.pendingCount,
        lastError: syncService.lastError,
      ),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status == null || !status.hasPendingScores) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getBackgroundColor(status),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getBorderColor(status),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIcon(status),
                  const SizedBox(width: 8),
                  _buildText(context, status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon(SyncStatus status) {
    if (status.isSyncing) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (status.hasError) {
      return const Icon(
        Icons.error_outline,
        size: 18,
        color: Colors.white,
      );
    }

    return const Icon(
      Icons.cloud_upload_outlined,
      size: 18,
      color: Colors.white,
    );
  }

  Widget _buildText(BuildContext context, SyncStatus status) {
    String text;

    if (status.isSyncing) {
      text = context.tr(LocaleKeys.syncingScores);
    } else if (status.hasError) {
      text = context.tr(LocaleKeys.syncError);
    } else {
      text = context.tr(LocaleKeys.pendingSyncCount, args: {
        'count': status.pendingCount.toString(),
      });
    }

    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Color _getBackgroundColor(SyncStatus status) {
    if (status.isSyncing) {
      return Colors.blue.shade700;
    }

    if (status.hasError) {
      return Colors.red.shade700;
    }

    return Colors.orange.shade700;
  }

  Color _getBorderColor(SyncStatus status) {
    if (status.isSyncing) {
      return Colors.blue.shade900;
    }

    if (status.hasError) {
      return Colors.red.shade900;
    }

    return Colors.orange.shade900;
  }
}

/// Detailed sync status dialog
class SyncStatusDialog extends StatelessWidget {
  final OfflineSyncService syncService;

  const SyncStatusDialog({
    super.key,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatus>(
      stream: syncService.syncStatus,
      initialData: SyncStatus(
        isSyncing: syncService.isSyncing,
        pendingCount: syncService.pendingCount,
        lastError: syncService.lastError,
      ),
      builder: (context, snapshot) {
        final status = snapshot.data!;

        return AlertDialog(
          title: Text(context.tr(LocaleKeys.offlineSyncStatus)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusRow(
                context,
                Icons.pending_actions,
                context.tr(LocaleKeys.pendingScores),
                status.pendingCount.toString(),
              ),
              const SizedBox(height: 12),
              _buildStatusRow(
                context,
                Icons.sync,
                context.tr(LocaleKeys.syncStatus),
                status.isSyncing
                    ? context.tr(LocaleKeys.syncing)
                    : context.tr(LocaleKeys.idle),
              ),
              if (status.hasError) ...[
                const SizedBox(height: 12),
                _buildStatusRow(
                  context,
                  Icons.error_outline,
                  context.tr(LocaleKeys.lastError),
                  status.lastError!,
                  isError: true,
                ),
              ],
            ],
          ),
          actions: [
            if (status.pendingCount > 0 && !status.isSyncing)
              TextButton.icon(
                onPressed: () async {
                  await syncService.forceSyncNow();
                },
                icon: const Icon(Icons.sync),
                label: Text(context.tr(LocaleKeys.syncNow)),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr(LocaleKeys.close)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isError = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isError ? Colors.red : Theme.of(context).iconTheme.color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isError ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context, OfflineSyncService syncService) {
    showDialog(
      context: context,
      builder: (context) => SyncStatusDialog(syncService: syncService),
    );
  }
}
