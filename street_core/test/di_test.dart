import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:street_core/core/di/injection.dart';
import 'package:street_core/features/auth/auth.dart';
import 'package:street_core/core/lang/bloc/locale_cubit.dart';
import 'package:street_core/core/theme/bloc/theme_cubit.dart';
import 'package:street_core/core/location/bloc/location_cubit.dart';
import 'package:street_core/features/public/site_config/site_config.dart';
import 'package:street_core/core/services/api_service.dart';
import 'package:street_core/core/helpers/device_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sl = GetIt.instance;

  setUp(() async {
    await sl.reset();
  });

  test('Dependency Injection should register all required Cubits', () async {
    // 1. Initialize DI
    await setupDependencyInjection();

    // 2. Verify registration of core cubits
    expect(sl.isRegistered<LocaleBloc>(), isTrue);
    expect(sl.isRegistered<ThemeCubit>(), isTrue);
    expect(sl.isRegistered<LocationCubit>(), isTrue);

    // 3. Verify registration of auth cubits
    expect(sl.isRegistered<UserCubit>(), isTrue);
    expect(sl.isRegistered<AuthCubit>(), isTrue);

    // 4. Verify registration of public cubits
    expect(sl.isRegistered<SiteConfigCubit>(), isTrue);

    // 5. Verify core services
    expect(sl.isRegistered<ApiService>(), isTrue);
    expect(sl.isRegistered<StorageService>(), isTrue);
  });
}
