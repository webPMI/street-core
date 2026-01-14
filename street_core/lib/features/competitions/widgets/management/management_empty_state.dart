/// Estado vacío para cuando no hay participantes
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';

class ManagementEmptyState extends StatelessWidget {
  const ManagementEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              context.tr(LocaleKeys.noParticipants),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(LocaleKeys.noParticipantsYet),
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
