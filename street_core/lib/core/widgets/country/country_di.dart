import 'package:get_it/get_it.dart';

import 'country_cubit.dart';
import 'country_repository.dart';
import 'country_repository_impl.dart';

void setupCountryDi(GetIt getIt) {
  /// Country Repository (no external dependencies) - Used by Auth, Profile
  if (!getIt.isRegistered<ICountryRepository>()) {
    getIt.registerLazySingleton<ICountryRepository>(CountryRepository.new);
  }

  /// Country Cubit - Manages country data (Singleton for sharing across app)
  if (!getIt.isRegistered<CountryCubit>()) {
    getIt.registerLazySingleton<CountryCubit>(
      () =>
          CountryCubit(getIt<ICountryRepository>())
            ..loadCountriesProgressively(),
    );
  }
}
