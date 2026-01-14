// lib/core/widgets/help_guide/bloc/guide_state.dart

import 'package:equatable/equatable.dart';
import '../models/guide_config.dart';

/// States for the guide system
abstract class GuideState extends Equatable {
  const GuideState();

  @override
  List<Object?> get props => [];
}

/// Initial state - guide system not initialized
class GuideInitial extends GuideState {
  const GuideInitial();
}

/// Loading guide data
class GuideLoading extends GuideState {
  const GuideLoading();
}

/// No guide available for current route
class GuideNotAvailable extends GuideState {
  final String routePath;

  const GuideNotAvailable(this.routePath);

  @override
  List<Object?> get props => [routePath];
}

/// Guide available but not shown (user dismissed or auto-show disabled)
class GuideAvailable extends GuideState {
  final GuideConfig config;
  final bool isDismissed;
  final int viewCount;

  const GuideAvailable({
    required this.config,
    required this.isDismissed,
    required this.viewCount,
  });

  @override
  List<Object?> get props => [config, isDismissed, viewCount];
}

/// Guide is being shown to user
class GuideShowing extends GuideState {
  final GuideConfig config;
  final int currentStep;

  const GuideShowing({
    required this.config,
    required this.currentStep,
  });

  /// Get total number of steps
  int get totalSteps => config.stepCount;

  /// Check if on first step
  bool get isFirstStep => currentStep == 0;

  /// Check if on last step
  bool get isLastStep => currentStep == totalSteps - 1;

  /// Get current step progress (1-based for display)
  String get stepProgress => '${currentStep + 1}/$totalSteps';

  @override
  List<Object?> get props => [config, currentStep];
}

/// Guide was dismissed by user
class GuideDismissed extends GuideState {
  final String routePath;
  final bool permanently;

  const GuideDismissed({
    required this.routePath,
    required this.permanently,
  });

  @override
  List<Object?> get props => [routePath, permanently];
}

/// Guide completed (user went through all steps)
class GuideCompleted extends GuideState {
  final String routePath;

  const GuideCompleted(this.routePath);

  @override
  List<Object?> get props => [routePath];
}

/// Error loading or showing guide
class GuideError extends GuideState {
  final String message;

  const GuideError(this.message);

  @override
  List<Object?> get props => [message];
}
