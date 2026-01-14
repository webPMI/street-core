/// Sección de todos los participantes registrados
/// Muestra la lista completa independiente del estado
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../models/participant.dart';
import 'management_empty_state.dart';
import 'participant_card.dart';

class AllParticipantsSection extends StatelessWidget {
  final List<Participant> participants;
  final Function(Participant)? onParticipantTap;

  const AllParticipantsSection({
    super.key,
    required this.participants,
    this.onParticipantTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        if (participants.isEmpty)
          const ManagementEmptyState()
        else
          ...participants.map(
            (participant) => ParticipantCard(
              participant: participant,
              onTap: onParticipantTap != null
                  ? () => onParticipantTap!(participant)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.people, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(LocaleKeys.allParticipants),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${participants.length} ${context.tr(LocaleKeys.registeredCount)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
