/// Participant Status Chip Widget
/// Displays participant status with color-coded badge.
/// Following Monolith-by-Features architecture (ADR-005).

import 'package:flutter/material.dart';

class ParticipantStatusChip extends StatelessWidget {
  const ParticipantStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = _getStatusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String, IconData) _getStatusStyle(String status) {
    switch (status) {
      case 'pending':
        return (Colors.orange, 'Pendiente', Icons.schedule);
      case 'approved':
        return (Colors.green, 'Aprobado', Icons.check_circle);
      case 'rejected':
        return (Colors.red, 'Rechazado', Icons.cancel);
      case 'checked_in':
        return (Colors.blue, 'Check-in', Icons.how_to_reg);
      default:
        return (Colors.grey, status, Icons.help_outline);
    }
  }

  /// Get status color for use in other widgets
  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'checked_in':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
