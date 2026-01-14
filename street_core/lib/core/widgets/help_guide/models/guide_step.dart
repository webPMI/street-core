// lib/core/widgets/help_guide/models/guide_step.dart

import 'package:equatable/equatable.dart';

/// Represents a single step in a help guide
class GuideStep extends Equatable {
  /// Translation key for the step title
  final String titleKey;

  /// Translation key for the step description
  final String descriptionKey;

  /// Optional icon to display with this step
  final String? icon;

  /// Optional target widget key to highlight (for future overlay feature)
  final String? targetKey;

  const GuideStep({
    required this.titleKey,
    required this.descriptionKey,
    this.icon,
    this.targetKey,
  });

  @override
  List<Object?> get props => [titleKey, descriptionKey, icon, targetKey];
}
