import 'package:get_it/get_it.dart';
import '../lang/bloc/locale_cubit.dart';
import '../theme/bloc/theme_cubit.dart';
import '../location/bloc/location_cubit.dart';
import '../widgets/help_guide/bloc/guide_cubit.dart';
import '../helpers/device_storage.dart'; // For ThemeCubit and LocaleCubit
import '../lang/locale_service.dart'; // For LocaleCubit
import '../location/location_service.dart';
import '../storage/hive_service.dart';
// For LocationCubit

/// Registers core Cubits and their immediate dependencies into GetIt.
///
/// These are typically Cubits that manage global, cross-feature state
/// or are foundational to the application's operation.
void setupCubits(GetIt getIt) {
  // Register common services needed by these core cubits
  // Replace with your actual implementations if they have dependencies.

  getIt.registerSingleton<LocaleBloc>(
    LocaleBloc(
      storage: getIt<StorageService>(),
      localeService: getIt<LocaleService>(),
    ),
  );
  getIt.registerSingleton<ThemeCubit>(
    ThemeCubit(storage: getIt<StorageService>()),
  );
  getIt.registerSingleton<LocationCubit>(
    LocationCubit(locationService: getIt<LocationService>()),
  );

  // Help Guide Cubit - Manages help guide system state
  getIt.registerSingleton<GuideCubit>(
    GuideCubit(hiveService: getIt<HiveService>()),
  );
}
