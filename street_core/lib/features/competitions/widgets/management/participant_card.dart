/// Tarjeta individual de participante (todos los estados)
/// Muestra información básica del participante con su estado
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../models/participant.dart';
import '../participant_status_chip.dart';

class ParticipantCard extends StatelessWidget {
  final Participant participant;
  final VoidCallback? onTap;

  const ParticipantCard({
    super.key,
    required this.participant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: ParticipantStatusChip.getStatusColor(
            participant.status,
          ),
          child: Text(
            participant.athleteName.isNotEmpty
                ? participant.athleteName[0].toUpperCase()
                : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          participant.athleteName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${context.tr(LocaleKeys.registrationNumber)} #${participant.registrationNumber}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: ParticipantStatusChip(status: participant.status),
      ),
    );
  }
}
