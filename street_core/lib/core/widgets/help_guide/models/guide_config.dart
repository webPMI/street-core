// lib/core/widgets/help_guide/models/guide_config.dart

import 'package:equatable/equatable.dart';
import 'guide_step.dart';

/// Configuration for a help guide associated with a specific route
class GuideConfig extends Equatable {
  /// Route path this guide is for (e.g., '/competitions/create')
  final String routePath;

  /// Translation key for the guide title
  final String titleKey;

  /// List of steps in this guide
  final List<GuideStep> steps;

  /// Whether this guide should auto-show on first visit
  final bool autoShow;

  const GuideConfig({
    required this.routePath,
    required this.titleKey,
    required this.steps,
    this.autoShow = true,
  });

  /// Number of steps in this guide
  int get stepCount => steps.length;

  @override
  List<Object?> get props => [routePath, titleKey, steps, autoShow];
}
