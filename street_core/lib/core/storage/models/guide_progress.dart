// lib/core/storage/models/guide_progress.dart

import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'guide_progress.g.dart';

/// Model for tracking which guides have been dismissed by the user
/// Stored locally using Hive to persist across sessions
@HiveType(typeId: 6)
class GuideProgress extends Equatable {
  /// Route path for which this guide applies (e.g., '/competitions/create')
  @HiveField(0)
  final String routePath;

  /// Whether the user has dismissed this guide permanently
  @HiveField(1)
  final bool isDismissed;

  /// When the guide was dismissed
  @HiveField(2)
  final DateTime? dismissedAt;

  /// How many times the user has seen this guide
  @HiveField(3)
  final int viewCount;

  /// Last time the guide was shown
  @HiveField(4)
  final DateTime? lastViewedAt;

  const GuideProgress({
    required this.routePath,
    this.isDismissed = false,
    this.dismissedAt,
    this.viewCount = 0,
    this.lastViewedAt,
  });

  /// Create a new guide progress entry
  factory GuideProgress.initial(String routePath) {
    return GuideProgress(
      routePath: routePath,
      isDismissed: false,
      viewCount: 0,
    );
  }

  /// Mark guide as viewed (increment count)
  GuideProgress markAsViewed() {
    return GuideProgress(
      routePath: routePath,
      isDismissed: isDismissed,
      dismissedAt: dismissedAt,
      viewCount: viewCount + 1,
      lastViewedAt: DateTime.now(),
    );
  }

  /// Mark guide as permanently dismissed
  GuideProgress dismiss() {
    return GuideProgress(
      routePath: routePath,
      isDismissed: true,
      dismissedAt: DateTime.now(),
      viewCount: viewCount,
      lastViewedAt: lastViewedAt,
    );
  }

  /// Reset dismissal (for testing or user preference changes)
  GuideProgress reset() {
    return GuideProgress(
      routePath: routePath,
      isDismissed: false,
      dismissedAt: null,
      viewCount: 0,
      lastViewedAt: null,
    );
  }

  /// Check if guide should be shown automatically
  /// Show only on first 2 visits if not dismissed
  bool get shouldShowAutomatically {
    return !isDismissed && viewCount < 2;
  }

  @override
  List<Object?> get props => [
        routePath,
        isDismissed,
        dismissedAt,
        viewCount,
        lastViewedAt,
      ];
}
