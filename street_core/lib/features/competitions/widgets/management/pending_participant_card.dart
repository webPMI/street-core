/// Tarjeta de participante pendiente con acciones de aprobación/rechazo
/// Incluye selección múltiple para bulk actions
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../../../core/lang/locale_helpers.dart';
import '../../models/participant.dart';

class PendingParticipantCard extends StatelessWidget {
  final Participant participant;
  final bool isSelected;
  final VoidCallback onToggleSelection;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PendingParticipantCard({
    super.key,
    required this.participant,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? Colors.orange.withAlpha(20) : null,
      child: InkWell(
        onTap: onToggleSelection,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => onToggleSelection(),
              ),
              CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  participant.athleteName.isNotEmpty
                      ? participant.athleteName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.athleteName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${context.tr(LocaleKeys.registered)}: ${participant.createdAt != null ? LocaleHelpers.formatDate(participant.createdAt!, context) : '-'}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onApprove,
                icon: const Icon(Icons.check_circle),
                color: Colors.green,
                tooltip: context.tr(LocaleKeys.approve),
              ),
              IconButton(
                onPressed: onReject,
                icon: const Icon(Icons.cancel),
                color: Colors.red,
                tooltip: context.tr(LocaleKeys.reject),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
