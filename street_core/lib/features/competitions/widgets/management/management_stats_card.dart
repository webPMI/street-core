/// Tarjeta de estadísticas del panel de gestión
/// Muestra contadores de participantes por estado
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';
import '../../../../core/lang/context_tr.dart';
import '../../../../core/lang/locale_keys.dart';
import '../../models/participant.dart';

class ManagementStatsCard extends StatelessWidget {
  final ParticipantCounts counts;
  final bool requiresApproval;

  const ManagementStatsCard({
    super.key,
    required this.counts,
    required this.requiresApproval,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  context.tr(LocaleKeys.managementPanel),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  context,
                  context.tr(LocaleKeys.pending),
                  counts.pending,
                  Colors.orange,
                ),
                _buildStatItem(
                  context,
                  context.tr(LocaleKeys.approved),
                  counts.approved,
                  Colors.green,
                ),
                _buildStatItem(
                  context,
                  context.tr(LocaleKeys.rejected),
                  counts.rejected,
                  Colors.red,
                ),
                _buildStatItem(
                  context,
                  context.tr(LocaleKeys.total),
                  counts.total,
                  Colors.blue,
                ),
              ],
            ),
            if (requiresApproval) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.approval, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      context.tr(LocaleKeys.requiresApproval),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
