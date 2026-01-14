/// Tournaments DI - Dependency injection setup for tournaments feature.
/// Following Monolith-by-Features architecture (ADR-005).

import '../../../core/services/api_service.dart';
import '../bloc/tournaments_cubit.dart';
import '../services/tournaments_service.dart';
import 'package:get_it/get_it.dart';

/// ============================================================================
/// TOURNAMENTS MODULE - Dependency Injection
/// ============================================================================
/// Complete tournaments feature setup.
/// Following Monolith-by-Features architecture (ADR-005).
/// ============================================================================

void setupTournamentsFeature(GetIt getIt) {
  // ============== SERVICES ==============

  /// Tournaments Service - Main service for tournaments
  getIt.registerLazySingleton<TournamentsService>(
    () => TournamentsService(getIt<ApiService>()),
  );

  // ============== CUBITS ==============

  /// Tournaments Cubit - Manages tournaments list and details
  getIt.registerFactory<TournamentsCubit>(
    () => TournamentsCubit(getIt<TournamentsService>()),
  );
}
