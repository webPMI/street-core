// lib/core/widgets/help_guide/bloc/guide_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../storage/hive_service.dart';
import '../../../storage/models/guide_progress.dart';
import '../../../helpers/logger.dart';
import '../services/guide_service.dart';
import 'guide_state.dart';

/// Cubit for managing help guide system
class GuideCubit extends Cubit<GuideState> {
  final HiveService _hiveService;

  GuideCubit({required HiveService hiveService})
      : _hiveService = hiveService,
        super(const GuideInitial());

  static const String _guideBoxName = 'guide_progress';

  /// Load guide for a specific route
  Future<void> loadGuideForRoute(String routePath) async {
    try {
      emit(const GuideLoading());

      // Check if guide exists for this route
      final guideConfig = GuideService.getGuideForRoute(routePath);
      if (guideConfig == null) {
        emit(GuideNotAvailable(routePath));
        return;
      }

      // Load user's progress for this guide
      final progress = _loadProgress(routePath);

      // If dismissed permanently, show as available but not auto-show
      if (progress.isDismissed) {
        emit(GuideAvailable(
          config: guideConfig,
          isDismissed: true,
          viewCount: progress.viewCount,
        ));
        return;
      }

      // If should auto-show (first 2 visits), show it
      if (guideConfig.autoShow && progress.shouldShowAutomatically) {
        await _incrementViewCount(routePath);
        emit(GuideShowing(config: guideConfig, currentStep: 0));
        return;
      }

      // Otherwise, make it available but don't show
      emit(GuideAvailable(
        config: guideConfig,
        isDismissed: false,
        viewCount: progress.viewCount,
      ));
    } catch (e) {
      AppLogger.error('Error loading guide', error: e, tag: 'GuideCubit');
      emit(GuideError('Error loading guide: $e'));
    }
  }

  /// Show guide manually (user tapped help button)
  Future<void> showGuide(String routePath) async {
    try {
      final guideConfig = GuideService.getGuideForRoute(routePath);
      if (guideConfig == null) {
        emit(GuideNotAvailable(routePath));
        return;
      }

      await _incrementViewCount(routePath);
      emit(GuideShowing(config: guideConfig, currentStep: 0));
    } catch (e) {
      AppLogger.error('Error showing guide', error: e, tag: 'GuideCubit');
      emit(GuideError('Error showing guide: $e'));
    }
  }

  /// Navigate to next step
  void nextStep() {
    if (state is GuideShowing) {
      final current = state as GuideShowing;
      if (current.isLastStep) {
        // Completed the guide
        _completeGuide(current.config.routePath);
      } else {
        emit(GuideShowing(
          config: current.config,
          currentStep: current.currentStep + 1,
        ));
      }
    }
  }

  /// Navigate to previous step
  void previousStep() {
    if (state is GuideShowing) {
      final current = state as GuideShowing;
      if (!current.isFirstStep) {
        emit(GuideShowing(
          config: current.config,
          currentStep: current.currentStep - 1,
        ));
      }
    }
  }

  /// Skip guide (close without completing)
  void skipGuide() {
    if (state is GuideShowing) {
      final current = state as GuideShowing;
      emit(GuideAvailable(
        config: current.config,
        isDismissed: false,
        viewCount: _loadProgress(current.config.routePath).viewCount,
      ));
    }
  }

  /// Dismiss guide permanently (don't show again)
  Future<void> dismissPermanently() async {
    if (state is GuideShowing) {
      final current = state as GuideShowing;
      await _dismissGuide(current.config.routePath);
      emit(GuideDismissed(
        routePath: current.config.routePath,
        permanently: true,
      ));
    }
  }

  /// Complete guide (user finished all steps)
  Future<void> _completeGuide(String routePath) async {
    await _dismissGuide(routePath);
    emit(GuideCompleted(routePath));
  }

  /// Reset guide progress (for testing or user preference)
  Future<void> resetGuide(String routePath) async {
    try {
      final key = _getStorageKey(routePath);
      await _hiveService.prefsBox.delete(key);
      AppLogger.info('Guide reset: $routePath', tag: 'GuideCubit');

      // Reload guide for current route
      await loadGuideForRoute(routePath);
    } catch (e) {
      AppLogger.error('Error resetting guide', error: e, tag: 'GuideCubit');
    }
  }

  /// Reset all guides
  Future<void> resetAllGuides() async {
    try {
      final allRoutes = GuideService.getAllGuideRoutes();
      for (final route in allRoutes) {
        await resetGuide(route);
      }
      AppLogger.info('All guides reset', tag: 'GuideCubit');
    } catch (e) {
      AppLogger.error('Error resetting all guides', error: e, tag: 'GuideCubit');
    }
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Load progress for a route
  GuideProgress _loadProgress(String routePath) {
    try {
      final key = _getStorageKey(routePath);
      final data = _hiveService.prefsBox.get(key);

      if (data == null) {
        return GuideProgress.initial(routePath);
      }

      // Deserialize from map
      return GuideProgress(
        routePath: routePath,
        isDismissed: data['isDismissed'] ?? false,
        dismissedAt: data['dismissedAt'] != null
            ? DateTime.parse(data['dismissedAt'])
            : null,
        viewCount: data['viewCount'] ?? 0,
        lastViewedAt: data['lastViewedAt'] != null
            ? DateTime.parse(data['lastViewedAt'])
            : null,
      );
    } catch (e) {
      AppLogger.error('Error loading progress', error: e, tag: 'GuideCubit');
      return GuideProgress.initial(routePath);
    }
  }

  /// Save progress
  Future<void> _saveProgress(GuideProgress progress) async {
    try {
      final key = _getStorageKey(progress.routePath);
      final data = {
        'isDismissed': progress.isDismissed,
        'dismissedAt': progress.dismissedAt?.toIso8601String(),
        'viewCount': progress.viewCount,
        'lastViewedAt': progress.lastViewedAt?.toIso8601String(),
      };
      await _hiveService.prefsBox.put(key, data);
    } catch (e) {
      AppLogger.error('Error saving progress', error: e, tag: 'GuideCubit');
    }
  }

  /// Increment view count
  Future<void> _incrementViewCount(String routePath) async {
    final progress = _loadProgress(routePath);
    final updated = progress.markAsViewed();
    await _saveProgress(updated);
  }

  /// Dismiss guide permanently
  Future<void> _dismissGuide(String routePath) async {
    final progress = _loadProgress(routePath);
    final updated = progress.dismiss();
    await _saveProgress(updated);
  }

  /// Get storage key for route
  String _getStorageKey(String routePath) {
    return 'guide_progress_$routePath';
  }
}
