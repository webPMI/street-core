import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Botón flotante para autocompletar formularios en desarrollo.
/// Solo visible en modo debug.
///
/// Uso simple:
/// ```dart
/// floatingActionButton: DevFillButton(
///   onFill: () => setState(() => _initialData = competitionMockData),
/// ),
/// ```
class DevFillButton extends StatelessWidget {
  const DevFillButton({
    super.key,
    required this.onFill,
    this.label = 'Fill',
  });

  final VoidCallback onFill;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      heroTag: 'dev_fill_button',
      backgroundColor: Colors.orange,
      onPressed: onFill,
      icon: const Icon(Icons.auto_fix_high, size: 20),
      label: Text(label),
    );
  }
}

/// Datos mock para el formulario de competiciones
Map<String, dynamic> competitionMockData = {
  'title': 'Campeonato Regional MX 2025',
  'description':
      'Gran campeonato regional de motocross con las mejores categorías. '
          'Inscripciones abiertas para pilotos de todas las edades. '
          'Premios para los tres primeros lugares.',
  'format': 'championship',
  'competitionType': 'individual',
  'discipline': 'motocross',
  'startDate': DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String(),
  'endDate': DateTime.now().add(const Duration(days: 31)).toUtc().toIso8601String(),
  'registrationDeadline':
      DateTime.now().add(const Duration(days: 25)).toUtc().toIso8601String(),
  'venue': 'Circuito Las Arenas',
  'city': 'Valencia',
  'country': 'España',
  'maxParticipants': 100,
  'minParticipants': 5,
  'entryFee': 50,
  'currency': 'EUR',
  'scoringType': 'points',
  'maxScore': 100,
  'totalRounds': 3,
  'rules': 'Reglamento FIM. Obligatorio equipo de protección completo.',
};
