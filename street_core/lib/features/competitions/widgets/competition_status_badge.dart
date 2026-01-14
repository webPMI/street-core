/// Widget de Insignia de Estado de Competición
/// Muestra el estado con icono y código de colores.
/// Siguiendo la arquitectura Monolith-by-Features (ADR-005).

import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

class CompetitionStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const CompetitionStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            )
          : const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withValues(alpha: 0.15),
            config.color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: config.color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: compact ? AppIconSize.xs : AppIconSize.sm,
            color: config.color,
          ),
          SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 13,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return _StatusConfig(
          'Borrador',
          Icons.edit_outlined,
          Colors.grey.shade700,
        );
      case 'published':
        return _StatusConfig(
          'Publicada',
          Icons.check_circle_outline,
          Colors.blue.shade600,
        );
      case 'upcoming':
        return _StatusConfig(
          'Próxima',
          Icons.schedule_outlined,
          Colors.orange.shade600,
        );
      case 'live':
        return _StatusConfig(
          'En Vivo',
          Icons.play_circle_outline,
          Colors.green.shade600,
        );
      case 'completed':
      case 'ended':
        return _StatusConfig(
          'Finalizada',
          Icons.flag_outlined,
          Colors.purple.shade600,
        );
      case 'cancelled':
        return _StatusConfig(
          'Cancelada',
          Icons.cancel_outlined,
          Colors.red.shade600,
        );
      case 'postponed':
        return _StatusConfig(
          'Aplazada',
          Icons.pause_circle_outline,
          Colors.amber.shade700,
        );
      default:
        return _StatusConfig(status, Icons.info_outline, Colors.grey.shade600);
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;

  _StatusConfig(this.label, this.icon, this.color);
}
