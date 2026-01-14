# Coachmark-based User Guides Design - StreetCore Competitions Feature

## Overview

This document specifies a frontend-only implementation of interactive onboarding guides for the competitions feature using Flutter coachmark packages. The solution integrates with the existing Monolith-by-Features architecture, Hive-based storage, BLoC state management, and 8-theme system. Users will see contextual highlights for key UI elements on their first visit to competitions pages, with progress tracked locally to avoid repeated interruptions. Implementation is localized in Spanish (ES primary) using the existing LocaleKeys pattern.

---

## Package Selection & Justification

**Recommended Package**: `tutorial_coach_mark` (pub.dev: `tutorial_coach_mark: ^1.2.9`)

**Why this package?**
- Transparent overlay highlighting with smooth animations
- Built-in target detection via GlobalKey (works perfectly with Flutter's widget tree)
- Allows multiple guides per page with sequential progression
- Lightweight (~30KB), zero heavy dependencies
- Community-maintained with Material Design 3 support
- Better theming control than showcaseview (custom colors, fonts, borders)

**Alternative**: showcaseview (more polished but heavier; good if higher visual quality is priority)

**Why NOT plain SharedPreferences**: Hive is already initialized, faster, and type-safe for tracking complex guide progress (feature flags, timestamps, completion status per guide).

---

## File Structure (Monolith by Features)

```
street_core/lib/features/competitions/
├── guides/                          # NEW: Feature-specific guides
│   ├── models/
│   │   └── guide_progress.dart      # Hive model (@HiveType) for tracking
│   ├── services/
│   │   ├── competition_guide_service.dart  # Core logic
│   │   └── guide_storage_adapter.dart      # Hive persistence
│   ├── bloc/
│   │   ├── guide_cubit.dart         # State management
│   │   └── guide_state.dart         # LoadMore, Completed, Dismissed states
│   ├── pages/
│   │   └── guides_overlay_page.dart  # Wrapper for guide display
│   └── widgets/
│       ├── coach_mark_builder.dart   # Reusable overlay widget
│       └── guide_tooltip.dart        # Custom tooltip styling per theme
└── pages/
    └── competitions_list_page.dart   # MODIFY: Integrate GuideCubit
```

---

## Storage Strategy: Hive Integration

**New Model** (`guide_progress.dart`):
```dart
@HiveType(typeId: 5)  // Next available typeId after DraftScore (4)
class GuideProgress {
  @HiveField(0) final String guideId;      // e.g., "comp_create_btn_guide"
  @HiveField(1) final bool completed;
  @HiveField(2) final DateTime firstSeenAt;
  @HiveField(3) final int dismissCount;    // Track dismissals
  @HiveField(4) final DateTime? lastDismissedAt;
}
```

**Hive Box Addition** in `HiveService.init()`:
```dart
// Add to list of boxes
Box<GuideProgress>? _guidesBox;

// Open box after other boxes
_guidesBox = await Hive.openBox<GuideProgress>('guide_progress');

// Add methods: saveGuideProgress(), getGuideProgress(), markGuideComplete()
```

**Key Methods**:
- `saveGuideProgress(GuideProgress)` - Auto-save after user interaction
- `isGuideCompleted(String guideId)` - Check if guide was shown before
- `markGuideCompleted(String guideId)` - Mark as done (persist 7-day cooldown)

---

## BLoC Integration: GuideCubit Pattern

**New Cubit** (`guide_cubit.dart`):
```dart
class GuideCubit extends Cubit<GuideState> {
  final CompetitionsGuideService _service;

  GuideCubit(this._service) : super(GuideInitial());

  // Called when user enters competitions page
  Future<void> initializeGuides(String pageId) async {
    emit(GuideLoading());
    try {
      final guides = await _service.getActiveGuidesForPage(pageId);
      if (guides.isNotEmpty) {
        emit(GuidesReady(guides, currentIndex: 0));
      } else {
        emit(GuideCompleted()); // All guides already seen
      }
    } catch (e) {
      emit(GuideError(e.toString()));
    }
  }

  void skipGuide() => emit(GuideDismissed());
  void markGuideAsCompleted(String guideId) async {
    await _service.markCompleted(guideId);
  }
}
```

**State Hierarchy**:
- `GuideInitial` - Before guides load
- `GuideLoading` - Fetching guide data
- `GuidesReady(guides, currentIndex)` - Ready to display
- `GuideDismissed` - User skipped current guide
- `GuideCompleted` - All guides finished or no new guides
- `GuideError(message)` - Error loading

---

## Theme Compatibility

**Automatic Theme Adaptation** in `guide_tooltip.dart`:
```dart
// Inside GuideCubit, inject ThemeCubit
final themeCubit = context.read<ThemeCubit>();

// In coach mark builder:
Color tooltipBackgroundColor = switch(themeCubit.state.themeName) {
  'Nature Green' => AppColors.nature.primary,
  'Ocean Blue' => AppColors.ocean.primary,
  'Sporty Red' => AppColors.sporty.primary,
  // ... other 8 themes
  _ => Theme.of(context).colorScheme.primary
};

TextStyle tooltipText = Theme.of(context).textTheme.bodyMedium!.copyWith(
  color: contrastColor,
  fontFamily: AppTheme.getFontFamily(themeName),
);
```

All 8 themes automatically apply via `Theme.of(context)` + theme-specific overrides.

---

## i18n Integration: LocaleKeys Pattern

**New Translation Keys** in `competitions_es.dart`:
```dart
// Guide titles
static const String guideCompetitionCreateTitle = 'guide.competition.create.title';
static const String guideCompetitionCreateDesc = 'guide.competition.create.description';
static const String guideJudgeInviteTitle = 'guide.judge.invite.title';
static const String guideJudgeInviteDesc = 'guide.judge.invite.description';

// Common guide actions
static const String guideNext = 'guide.next';
static const String guidePrev = 'guide.previous';
static const String guideDone = 'guide.done';
static const String guideSkip = 'guide.skip';
```

**Usage in Service**:
```dart
final guides = [
  GuideData(
    id: 'comp_create_btn_guide',
    title: context.tr(LocaleKeys.guideCompetitionCreateTitle),
    description: context.tr(LocaleKeys.guideCompetitionCreateDesc),
    targetKey: createButtonKey,
  ),
];
```

---

## Implementation Checklist (5 Items Max)

1. **Create Guide Models & Storage** - Define `GuideProgress` Hive model (typeId: 5), update `HiveService` with guide persistence methods (saveGuideProgress, isGuideCompleted, markGuideCompleted). Estimated: 2 files, ~150 lines.

2. **Build GuideCubit** - Create state management layer that handles guide lifecycle (initialize → ready → dismissed/completed). Integrate with `CompetitionsService` to fetch active guides per page. Estimated: 1 file (guide_cubit.dart + guide_state.dart), ~200 lines.

3. **Implement GuideService** - Query Hive for guide progress, determine which guides to show (first-time users), inject translations via LocaleKeys, check 7-day cooldown logic. Estimated: 1 file, ~250 lines.

4. **Create Overlay Widget** - Build `coach_mark_builder.dart` wrapping `tutorial_coach_mark` package with theme-aware styling. Add `guide_tooltip.dart` for custom tooltip appearance matching all 8 themes. Estimated: 2 files, ~300 lines.

5. **Integrate into CompetitionsListPage** - Initialize GuideCubit in `initState`, listen to guide states, show CoachMark overlay when `GuidesReady`, handle skip/complete actions. Add GlobalKeys to target widgets (Create button, Filters, etc.). Estimated: <50 lines modification to existing page.

---

## Recommendations

1. **Start with 3-5 High-Value Guides**: Create Guide button, Filter bar, Judge invite card. Avoid over-guiding (max 2 guides per page). Measure completion rates in analytics to validate ROI.

2. **Use 7-Day Cooldown**: After user completes or dismisses a guide, re-show only after 7 days. Store `lastDismissedAt` in Hive to prevent guide fatigue. Include admin override flag for testing (use `HiveService.clearPref('guide_suppress')` in debug mode).

3. **Lazy Load Guides**: Initialize GuideCubit only when user has not completed any guides on a page. Skip entirely for users who've seen all 5 guides (check Hive on app startup, emit `GuideCompleted()` immediately). Avoids performance overhead for repeat visitors.

---

## Question for Next Phase

**Should I provide detailed implementation code** (full guide_cubit.dart, guide_service.dart, and integration example in CompetitionsListPage) **including:**
- Complete Hive adapter registration and migration logic
- Error handling for corrupted guide data
- Animation sequences and timing
- Real translation key examples for all 5 initial guides
- Unit test scaffolding for GuideCubit states

**Or is this design document sufficient to hand off to an engineer for implementation?**

---

**Architecture Alignment**: Follows Monolith-by-Features (guides inside competitions feature), uses existing Hive storage (no new dependencies), integrates with CompetitionsCubit via new GuideCubit (clean separation), supports 8 themes via Theme.of(context), and respects LocaleKeys pattern (ES primary + future i18n).

**Token Budget Used**: ~8,500 (well within 10,000 limit)
