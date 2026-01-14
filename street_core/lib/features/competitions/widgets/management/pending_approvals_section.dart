/// Sección de aprobaciones pendientes con acciones masivas
/// Incluye header con controles de selección y botones bulk
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../models/participant.dart';
import 'pending_participant_card.dart';

class PendingApprovalsSection extends StatelessWidget {
  final List<Participant> participants;
  final Set<String> selectedIds;
  final Function(String) onToggleSelection;
  final VoidCallback onSelectAll;
  final Function(Participant) onApprove;
  final Function(Participant) onReject;
  final VoidCallback onBulkApprove;
  final VoidCallback onBulkReject;

  const PendingApprovalsSection({
    super.key,
    required this.participants,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onApprove,
    required this.onReject,
    required this.onBulkApprove,
    required this.onBulkReject,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _buildHeader(context),
        ...participants.map(
          (participant) => PendingParticipantCard(
            participant: participant,
            isSelected: selectedIds.contains(participant.id),
            onToggleSelection: () => onToggleSelection(participant.id),
            onApprove: () => onApprove(participant),
            onReject: () => onReject(participant),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pending_actions, color: Colors.orange[700]),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(LocaleKeys.pendingApproval),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${participants.length} ${context.tr(LocaleKeys.requests)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          if (selectedIds.isNotEmpty)
            Row(
              children: [
                IconButton(
                  onPressed: onBulkApprove,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  tooltip: context.tr(LocaleKeys.approveSelected),
                ),
                IconButton(
                  onPressed: onBulkReject,
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  tooltip: context.tr(LocaleKeys.rejectSelected),
                ),
              ],
            )
          else
            TextButton.icon(
              onPressed: onSelectAll,
              icon: const Icon(Icons.select_all, size: 18),
              label: Text(context.tr(LocaleKeys.selectAll)),
            ),
        ],
      ),
    );
  }
}
