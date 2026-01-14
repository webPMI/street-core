/// Competitions DI - Dependency injection setup for competitions feature.
/// Following Monolith-by-Features architecture (ADR-005).

import '/features/competitions/di/competitions_nav.dart';

import '../../../core/services/api_service.dart';
import '../../../core/storage/hive_service.dart';
import '../bloc/competitions_cubit.dart';
import '../categories/bloc/competition_category_cubit.dart';
import '../judges/bloc/judge_invitation_cubit.dart';
import '../judges/bloc/judge_score_cubit.dart';
import '../repositories/competition_category_repository.dart';
import '../repositories/heat_repository.dart';
import '../repositories/judge_invitation_repository.dart';
import '../repositories/judge_score_repository.dart';
import '../services/competitions_service.dart';
import '../services/participant_service.dart';
import '../services/offline_sync_service.dart';
import '../services/outbox_service.dart';
import '../services/score_validation_service.dart';
import 'package:get_it/get_it.dart';

/// ============================================================================
/// COMPETITIONS MODULE - Dependency Injection (CONSOLIDATED)
/// ============================================================================
/// Complete competitions feature with all sub-modules.
/// Migrated from presentation/competitions/ to features/competitions/
/// Following Monolith-by-Features architecture (ADR-005).
/// ============================================================================

void setupCompeFeature(GetIt getIt) {
  setupCompeNavigation();

  // ============== SERVICES ==============

  /// Competitions Service - Main service for competitions
  getIt.registerLazySingleton<CompetitionsService>(
    () => CompetitionsService(getIt<ApiService>()),
  );

  /// Participant Service - Manage competition participants
  getIt.registerLazySingleton<ParticipantService>(
    () => ParticipantService(getIt<ApiService>()),
  );

  /// Offline Sync Service - Syncs offline scores when connection is restored
  getIt.registerLazySingleton<OfflineSyncService>(
    () => OfflineSyncService(
      hiveService: getIt<HiveService>(),
      scoreRepository: getIt<JudgeScoreRepository>(),
    ),
  );

  /// Outbox Service - CONTINGENCIA 1: Patrón Outbox para scores offline
  getIt.registerLazySingleton<OutboxService>(
    () => OutboxService(
      hiveService: getIt<HiveService>(),
      repository: getIt<JudgeScoreRepository>(),
    ),
  );

  /// Score Validation Service - CONTINGENCIA 2: Validación heurística
  getIt.registerLazySingleton<ScoreValidationService>(
    () => ScoreValidationService(),
  );

  // ============== REPOSITORIES ==============

  /// Competition Category Repository
  getIt.registerLazySingleton<CompetitionCategoryRepository>(
    () => CompetitionCategoryRepository(getIt<ApiService>()),
  );

  /// Judge Invitation Repository
  getIt.registerLazySingleton<JudgeInvitationRepository>(
    () => JudgeInvitationRepository(getIt<ApiService>()),
  );

  /// Judge Score Repository
  getIt.registerLazySingleton<JudgeScoreRepository>(
    () => JudgeScoreRepository(getIt<ApiService>()),
  );

  /// Heat Repository - Manages competition heats
  getIt.registerLazySingleton<HeatRepository>(
    () => HeatRepository(getIt<ApiService>()),
  );

  // ============== CUBITS ==============

  /// Competitions Cubit - Manages competitions list and details
  getIt.registerFactory<CompetitionsCubit>(
    () => CompetitionsCubit(getIt<CompetitionsService>()),
  );

  /// Competition Category Cubit - Manages competition categories
  getIt.registerFactory<CompetitionCategoryCubit>(
    () => CompetitionCategoryCubit(getIt<CompetitionCategoryRepository>()),
  );

  /// Judge Invitation Cubit - Manages judge invitations
  getIt.registerFactory<JudgeInvitationCubit>(
    () => JudgeInvitationCubit(getIt<JudgeInvitationRepository>()),
  );

  /// Judge Score Cubit - Manages judge scoring (with offline support + heat management)
  getIt.registerFactory<JudgeScoreCubit>(
    () => JudgeScoreCubit(
      getIt<JudgeScoreRepository>(),
      getIt<HeatRepository>(),
      hiveService: getIt<HiveService>(),
    ),
  );
}
