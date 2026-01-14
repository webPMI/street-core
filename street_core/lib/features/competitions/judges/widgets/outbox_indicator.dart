/// Outbox Indicator Widget - Icono de sincronización en AppBar
///
/// CONTINGENCIA 1: "Efecto Estadio"
/// Muestra el estado de sincronización de scores:
/// - Nube con check (verde): Todo sincronizado
/// - Nube tachada (roja): Hay scores pendientes en el Outbox
/// Al tocar, muestra lista de pendientes + opción "Reintentar todo"

import 'package:flutter/material.dart';
import '../../../../core/widgets/my_text.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/helpers/snackbar_helper.dart';
import '../../services/outbox_service.dart';
import '../../models/offline_score.dart';

/// Widget that displays outbox sync status in AppBar
class OutboxIndicator extends StatelessWidget {
  const OutboxIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final outboxService = getIt<OutboxService>();

    return StreamBuilder<OutboxStatus>(
      stream: outboxService.statusStream,
      initialData: const OutboxStatus(unsyncedCount: 0),
      builder: (context, snapshot) {
        final status = snapshot.data!;
        final hasPending = status.hasPendingScores;

        return IconButton(
          icon: Stack(
            children: [
              Icon(
                hasPending ? Icons.cloud_off : Icons.cloud_done,
                color: hasPending ? Colors.red : Colors.green,
                size: 28,
              ),
              if (hasPending)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        status.unsyncedCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: hasPending
              ? context.tr(LocaleKeys.scorePendingSync)
              : context.tr(LocaleKeys.syncSuccessful),
          onPressed: hasPending
              ? () => _showOutboxBottomSheet(context, outboxService)
              : null,
        );
      },
    );
  }

  void _showOutboxBottomSheet(
    BuildContext context,
    OutboxService outboxService,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _OutboxBottomSheet(outboxService: outboxService),
    );
  }
}

/// Bottom sheet that shows pending scores and retry options
class _OutboxBottomSheet extends StatefulWidget {
  const _OutboxBottomSheet({required this.outboxService});

  final OutboxService outboxService;

  @override
  State<_OutboxBottomSheet> createState() => _OutboxBottomSheetState();
}

class _OutboxBottomSheetState extends State<_OutboxBottomSheet> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyText(
                      LocaleKeys.scorePendingSync,
                      istitle: true,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MyText(
                LocaleKeys.scorePendingSyncMessage,
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              const Divider(height: 24),

              // List of pending scores
              Expanded(
                child: FutureBuilder<List<OfflineScore>>(
                  future: Future.value(widget.outboxService.getPendingScores()),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                       return const Center(child: CircularProgressIndicator());
                    }

                    final pendingScores = snapshot.data!;

                    if (pendingScores.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_done,
                              size: 64,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            MyText(
                              LocaleKeys.syncSuccessful,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: pendingScores.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final score = pendingScores[index];
                        return _buildPendingScoreTile(context, score);
                      },
                    );
                  },
                ),
              ),

              const Divider(height: 24),

              // Retry all button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _retryAll,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: MyText(
                    _isRetrying
                        ? LocaleKeys.retryingSubmission
                        : LocaleKeys.retrySyncAll,
                    color: Colors.white,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingScoreTile(BuildContext context, OfflineScore score) {
    final theme = Theme.of(context);
    final hasMaxAttempts = score.maxSyncAttemptsReached;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: hasMaxAttempts ? Colors.red : Colors.orange,
        child: Icon(
          hasMaxAttempts ? Icons.error : Icons.schedule,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: MyText(
        'Score #${score.participantId.substring(score.participantId.length - 4)}',
        noTranslation: true,
        fontWeight: FontWeight.bold,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            'Total: ${score.totalScore.toStringAsFixed(1)}',
            noTranslation: true,
            fontSize: 12,
          ),
          MyText(
            '${context.tr(LocaleKeys.retryAttempt)}: ${score.syncAttempts}/5',
            fontSize: 12,
            color: hasMaxAttempts ? Colors.red : theme.textTheme.bodySmall?.color,
          ),
        ],
      ),
      trailing: hasMaxAttempts
          ? const Icon(Icons.warning, color: Colors.red)
          : IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => _retrySingle(score),
              tooltip: context.tr(LocaleKeys.retrySync),
            ),
    );
  }

  Future<void> _retryAll() async {
    setState(() => _isRetrying = true);

    try {
      final result = await widget.outboxService.retryAll();

      if (!mounted) return;

      if (result.noConnection) {
        SnackBarHelper.showError(context, LocaleKeys.syncNoConnection);
      } else if (result.allSucceeded) {
        SnackBarHelper.showSuccess(context, LocaleKeys.syncSuccessful);
        Navigator.of(context).pop(); // Close bottom sheet
      } else if (result.someSucceeded) {
        SnackBarHelper.showCustom(
          context,
          '${result.successCount}/${result.totalAttempted} ${context.tr(LocaleKeys.syncBatchComplete)}',
          type: SnackBarType.warning,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  Future<void> _retrySingle(OfflineScore score) async {
    final result = await widget.outboxService.retrySingle(score);

    if (!mounted) return;

    switch (result) {
      case OutboxSyncResult.success:
        SnackBarHelper.showSuccess(context, LocaleKeys.syncSuccessful);
        break;
      case OutboxSyncResult.noConnection:
        SnackBarHelper.showError(context, LocaleKeys.syncNoConnection);
        break;
      case OutboxSyncResult.maxAttemptsReached:
        SnackBarHelper.showError(context, LocaleKeys.syncMaxAttemptsReached);
        break;
      default:
        SnackBarHelper.showWarning(context, LocaleKeys.syncFailed);
    }

    // Refresh UI
    setState(() {});
  }
}
