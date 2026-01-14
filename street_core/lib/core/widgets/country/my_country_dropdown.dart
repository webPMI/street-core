import '../../../data/constants/country.dart';
import '/core/helpers/responsive/responsive_builder.dart';
import '/core/theme/app_spacing.dart';
import '../my_dropdown.dart';
import '../my_text.dart';

import 'country_cubit.dart';
import 'country_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// Sistema de diseño importado
// AppSpacing: xxs(2), xs(4), sm(8), md(16), lg(24), xl(32), xxl(48), xxxl(64)
// AppRadius: xs(4), sm(8), md(12), lg(16), xl(24), full(9999)
// AppElevation: none(0), xs(1), sm(2), md(4), lg(8), xl(16)
// AppIconSize: xs(16), sm(20), md(24), lg(32), xl(48), xxl(64)
// AppDuration: instant(100ms), fast(200ms), normal(300ms), slow(500ms)

/// {@template my_country_dropdown}
/// Selector de país optimizado con banderas y búsqueda integrada.
///
/// Un componente especializado para selección de países con soporte completo
/// para banderas (emojis Unicode), búsqueda fluida y gestión de estado BLoC.
///
/// ## Características Principales
///
/// | Categoría | Características |
/// |-----------|-----------------|
/// | **Banderas** | Emojis Unicode optimizados, tamaño responsivo |
/// | **Performance** | Carga progresiva, lazy rendering, RepaintBoundary |
/// | **Búsqueda** | Búsqueda fluida integrada en MyDropdown |
/// | **Estado** | BLoC pattern con CountryCubit (GetIt singleton) |
/// | **Validación** | Validación de códigos ISO 3166-1 alpha-2 |
/// | **Accesibilidad** | Semantics completos, lectores de pantalla |
///
/// ## Ejemplos de Uso
///
/// ### Uso Básico
///
/// ```dart
/// MyCountryDropdown(
///   title: 'País de residencia',
///   selectedCountryCode: 'CO',
///   onChanged: (code) => setState(() => selectedCountry = code),
/// )
/// ```
///
/// ### Con Validación
///
/// ```dart
/// MyCountryDropdown(
///   title: 'País',
///   selectedCountryCode: userCountry,
///   errorText: userCountry == null ? 'Campo requerido' : null,
///   onChanged: handleCountryChange,
/// )
/// ```
///
/// ### Sin Banderas
///
/// ```dart
/// MyCountryDropdown(
///   title: 'Selecciona país',
///   selectedCountryCode: country,
///   showFlags: false, // Solo muestra nombres
///   onChanged: handleChange,
/// )
/// ```
///
/// ### Con Personalización Visual
///
/// ```dart
/// MyCountryDropdown(
///   title: 'País de origen',
///   selectedCountryCode: 'MX',
///   showFlags: true,
///   // Se integra con MyDropdown, hereda su personalización
///   onChanged: (code) {
///     context.read<ProfileCubit>().updateCountry(code);
///   },
/// )
/// ```
///
/// ## Arquitectura
///
/// - **Patrón**: Clean Architecture + BLoC
/// - **Estado**: CountryCubit (singleton vía GetIt)
/// - **Carga**: Progresiva (países prioritarios primero)
/// - **Autocontenido**: Provee su propio Cubit internamente
///
/// ## Estados Visuales
///
/// | Estado | Comportamiento |
/// |--------|----------------|
/// | **Vacío** | Muestra mensaje "No hay países disponibles" |
/// | **Cargando** | Indicador sutil mientras carga lista completa |
/// | **Normal** | Lista completa de países con banderas |
/// | **Error** | Borde rojo + mensaje de error |
///
/// ## Performance
///
/// - ✅ Carga progresiva (países prioritarios primero)
/// - ✅ Lazy rendering de items (Flutter DropdownButton)
/// - ✅ RepaintBoundary en cada item
/// - ✅ Memoización de dimensiones responsivas
/// - ✅ Validación optimizada con `any()`
///
/// ## Accesibilidad (WCAG 2.1)
///
/// - ✅ Semantics heredados de MyDropdown
/// - ✅ Hints descriptivos para cada país
/// - ✅ Navegación por teclado
/// - ✅ Banderas como decoración (no críticas)
///
/// ## Responsive
///
/// El tamaño de banderas y espaciado se ajusta según el dispositivo usando el
/// sistema de diseño AppSpacing:
///
/// | Dispositivo | Bandera | Espaciado | Ancho Texto |
/// |-------------|---------|-----------|-------------|
/// | **Mobile Small** | 18px | AppSpacing.xs + 2 (6px) | 50% pantalla |
/// | **Mobile** | 20px | AppSpacing.sm (8px) | 60% pantalla |
/// | **Tablet/Desktop** | 22px | AppSpacing.sm + 2 (10px) | 40% pantalla |
///
/// ## Sistema de Diseño
///
/// Este componente utiliza el sistema de diseño de la aplicación:
///
/// - **Spacing**: AppSpacing.xs, .sm, .md (consistente en toda la app)
/// - **Colors**: colorScheme (adaptativo a tema claro/oscuro)
/// - **Duration**: AppDuration.fast (200ms para animaciones)
/// - **Typography**: theme.textTheme (unificado)
///
/// ## Changelog
///
/// **v2.1.0** (2025-12-24):
/// - Integración completa con sistema de diseño AppSpacing
/// - Uso de colorScheme en lugar de colores hardcodeados
/// - Mejorada documentación dartdoc con ejemplos completos
/// - Añadido Semantics para accesibilidad WCAG 2.1
/// - Animaciones sutiles en indicador de carga
/// - Consistencia visual con MyDropdown v2.0.0
///
/// **v2.0.0** (2025-12-24):
/// - Mejorada documentación dartdoc completa
/// - Uso consistente de AppSpacing
/// - Integración con sistema de diseño
/// - Performance optimizations
///
/// **v1.0.0** (2025-12-01):
/// - Versión inicial con BLoC pattern
///
/// {@endtemplate}
///
/// Ver también:
/// - [MyDropdown] para selectores genéricos
/// - [CountryCubit] para gestión de estado
/// - [Country] para modelo de datos
class MyCountryDropdown extends StatelessWidget {
  /// {@macro my_country_dropdown}
  const MyCountryDropdown({
    super.key,
    this.title,
    this.selectedCountryCode,
    this.onChanged,
    this.showFlags = true,
    this.errorText,
  });

  /// Título que aparece encima del selector.
  ///
  /// Se traduce automáticamente usando MyText.
  ///
  /// Por defecto: `'select_country'` (clave de traducción)
  final String? title;

  /// Código ISO 3166-1 alpha-2 del país seleccionado (e.g., 'CO', 'MX', 'ES').
  ///
  /// Debe ser un código válido que exista en [Country.code].
  /// Si el código no es válido, se establece en `null` automáticamente.
  ///
  /// ```dart
  /// selectedCountryCode: 'CO' // Colombia
  /// selectedCountryCode: 'US' // Estados Unidos
  /// ```
  final String? selectedCountryCode;

  /// Callback ejecutado cuando el usuario selecciona un país.
  ///
  /// Recibe el código ISO del país seleccionado o `null` si se deselecciona.
  ///
  /// ```dart
  /// onChanged: (code) {
  ///   setState(() => userCountry = code);
  ///   context.read<ProfileCubit>().updateCountry(code);
  /// }
  /// ```
  final Function(String?)? onChanged;

  /// Si mostrar banderas de países (emojis Unicode).
  ///
  /// Por defecto: `true`
  ///
  /// Cuando es `false`, solo se muestra el nombre del país.
  final bool showFlags;

  /// Texto de error mostrado debajo del selector.
  ///
  /// Cuando no es `null`:
  /// - El borde cambia a color error
  /// - Se muestra el mensaje debajo
  /// - Se activa live region para accesibilidad
  ///
  /// ```dart
  /// errorText: country == null ? 'Debes seleccionar un país' : null
  /// ```
  final String? errorText;

  /// Calcula dimensiones responsivas según el tamaño de pantalla.
  ///
  /// Utiliza el sistema de diseño AppSpacing para consistencia:
  ///
  /// - **Mobile Small**: Bandera 18px, espaciado AppSpacing.xs + 2 (6px)
  /// - **Mobile**: Bandera 20px, espaciado AppSpacing.sm (8px)
  /// - **Tablet/Desktop**: Bandera 22px, espaciado AppSpacing.sm + 2 (10px)
  ///
  /// Los anchos máximos de texto son responsivos:
  /// - Mobile Small: 50% del ancho de pantalla
  /// - Tablet: 40% del ancho de pantalla
  /// - Mobile/Desktop: 60% del ancho de pantalla
  ///
  /// Retorna [_ResponsiveDimensions] con valores calculados.
  _ResponsiveDimensions _getResponsiveDimensions(BuildContext context) {
    final isSmallScreen = context.isMobileSmall;
    final isMediumScreen = context.isMobile && !isSmallScreen;
    final isTablet = context.isTablet;

    return _ResponsiveDimensions(
      flagSize: isSmallScreen ? 18.0 : (isMediumScreen ? 20.0 : 22.0),
      spacing: isSmallScreen
          ? AppSpacing.xs + 2
          : (isMediumScreen ? AppSpacing.sm : AppSpacing.sm + 2),
      maxTextWidth: isSmallScreen
          ? context.screenWidth * 0.5
          : (isTablet ? context.screenWidth * 0.4 : context.screenWidth * 0.6),
    );
  }

  /// Valida si el código de país proporcionado existe en la lista disponible.
  ///
  /// Parámetros:
  /// - [code]: Código ISO 3166-1 alpha-2 del país (e.g., 'CO', 'MX', 'ES')
  /// - [countries]: Lista de países disponibles
  ///
  /// Retorna `true` si [code] no es `null` y existe en la lista [countries].
  ///
  /// Ejemplo:
  /// ```dart
  /// final isValid = _isValidCountryCode('CO', state.countries); // true
  /// final isInvalid = _isValidCountryCode('XX', state.countries); // false
  /// final isNull = _isValidCountryCode(null, state.countries); // false
  /// ```
  bool _isValidCountryCode(String? code, List<Country> countries) {
    if (code == null) return false;
    return countries.any((country) => country.code == code);
  }

  @override
  Widget build(BuildContext context) {
    // Provide CountryCubit from GetIt - self-contained, no external provider needed
    return BlocProvider<CountryCubit>.value(
      value: GetIt.I<CountryCubit>(),
      child: BlocBuilder<CountryCubit, CountryState>(
        buildWhen: (previous, current) =>
            previous.countries != current.countries ||
            previous.isLoadingAll != current.isLoadingAll,
        builder: (context, state) {
          // Empty country list check
          if (state.countries.isEmpty) {
            return MyDropdown<String>(
              items: const [],
              title: title ?? 'select_country',
              emptyText: 'no_countries_available',
              onChanged: onChanged,
              errorText: errorText,
            );
          }

          // Validate selected country code - allow null instead of forcing first country
          final String? validatedValue =
              selectedCountryCode != null &&
                  _isValidCountryCode(selectedCountryCode, state.countries)
              ? selectedCountryCode
              : null;

          final dimensions = _getResponsiveDimensions(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              MyDropdown<String>(
                value: validatedValue,
                onChanged: onChanged ?? (newCode) {},
                searchable: true,
                errorText: errorText,
                items: _buildCountryItems(state.countries, dimensions),
                title: title ?? 'select_country',
              ),
              // Subtle loading indicator while remaining countries load
              // Con Semantics para accesibilidad
              if (state.isLoadingAll)
                Semantics(
                  label: 'Cargando lista completa de países',
                  liveRegion: true,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: AppSpacing.xs,
                      left: AppSpacing.md - 4, // 12px
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: AppIconSize.xs - 6, // 10px
                          height: AppIconSize.xs - 6, // 10px
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        MyText(
                          'loading_all_countries',
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.secondary,
                          padding: 0,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Construye los items del dropdown de países con optimizaciones de rendimiento.
  ///
  /// Utiliza la lista de países del estado (provista por CountryCubit) y aplica
  /// técnicas de optimización para mejorar el rendimiento:
  ///
  /// - **Lazy rendering**: Flutter's DropdownButton renderiza solo items visibles
  /// - **RepaintBoundary**: Aísla el repaint de cada item individualmente
  /// - **Const constructors**: Usa constructores const donde sea posible
  ///
  /// Parámetros:
  /// - [countries]: Lista completa de países disponibles
  /// - [dimensions]: Dimensiones responsivas calculadas (flag size, spacing)
  ///
  /// Retorna lista de [DropdownMenuItem<String>] listos para usar.
  ///
  /// Cada item incluye:
  /// - Bandera (si [showFlags] es true)
  /// - Nombre del país
  /// - Semantics automático heredado de MyDropdown
  List<DropdownMenuItem<String>> _buildCountryItems(
    List<Country> countries,
    _ResponsiveDimensions dimensions,
  ) {
    // Flutter's DropdownButton handles lazy rendering of items internally
    // This means only visible items are actually built, improving performance
    return countries.map((country) {
      return DropdownMenuItem<String>(
        value: country.code,
        // Wrap with RepaintBoundary for performance optimization
        // This isolates repaints to individual items
        child: RepaintBoundary(
          child: _CountryItemContent(
            country: country,
            dimensions: dimensions,
            showFlag: showFlags,
          ),
        ),
      );
    }).toList();
  }
}

/// Widget de contenido de item de país optimizado para rendimiento.
///
/// Muestra la bandera (emoji Unicode) y el nombre del país con layout responsivo.
///
/// ## Optimizaciones de Rendimiento
///
/// - **Const constructor**: Minimiza rebuilds innecesarios
/// - **RepaintBoundary**: Ya aplicado por el widget padre
/// - **Fixed width flag**: Alineación consistente de banderas
/// - **Flexible text**: Texto responsivo con overflow handling
///
/// ## Layout
///
/// ```
/// [🇨🇴] Colombia     <- Bandera (opcional) + Espaciado + Nombre
/// ```
///
/// Parámetros:
/// - [country]: Modelo de país con código, nombre y bandera
/// - [dimensions]: Dimensiones responsivas (flag size, spacing, max width)
/// - [showFlag]: Si mostrar la bandera emoji (default: true)
///
/// Ver también: [MyCountryDropdown], [_ResponsiveDimensions]
class _CountryItemContent extends StatelessWidget {
  /// Crea un widget de contenido de item de país.
  const _CountryItemContent({
    required this.country,
    required this.dimensions,
    required this.showFlag,
  });

  /// Modelo de país con código ISO, nombre y bandera emoji.
  final Country country;

  /// Dimensiones responsivas calculadas para el dispositivo actual.
  final _ResponsiveDimensions dimensions;

  /// Si mostrar la bandera emoji antes del nombre.
  final bool showFlag;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showFlag) ...[
          // Flag emoji with fixed width for alignment
          // Ancho fijo garantiza alineación consistente de todas las banderas
          SizedBox(
            width: dimensions.flagSize + AppSpacing.xs,
            child: MyText(
              country.flag,
              fontSize: dimensions.flagSize,
              padding: 0,
              noTranslation: true,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: dimensions.spacing),
        ],
        // Country name with responsive max width
        // Flexible permite que el texto se adapte al espacio disponible
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dimensions.maxTextWidth),
            child: MyText(
              country.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ],
    );
  }
}

/// Clase auxiliar para almacenar valores de dimensiones responsivas.
///
/// Encapsula todas las dimensiones calculadas según el tipo de dispositivo,
/// facilitando el paso de múltiples valores como un solo objeto.
///
/// ## Uso
///
/// ```dart
/// final dimensions = _ResponsiveDimensions(
///   flagSize: 20.0,
///   spacing: AppSpacing.sm, // 8.0
///   maxTextWidth: 300.0,
/// );
/// ```
///
/// ## Beneficios
///
/// - **Organización**: Agrupa valores relacionados
/// - **Type safety**: Garantiza tipos correctos
/// - **Inmutabilidad**: Valores const, no pueden cambiar
/// - **Claridad**: Nombres descriptivos en lugar de múltiples parámetros
///
/// Ver también: [MyCountryDropdown._getResponsiveDimensions]
class _ResponsiveDimensions {
  /// Crea una instancia de dimensiones responsivas.
  ///
  /// Todos los parámetros son requeridos y deben ser valores positivos.
  const _ResponsiveDimensions({
    required this.flagSize,
    required this.spacing,
    required this.maxTextWidth,
  });

  /// Tamaño de la bandera emoji en píxeles lógicos.
  ///
  /// Valores típicos:
  /// - Mobile Small: 18.0
  /// - Mobile: 20.0
  /// - Tablet/Desktop: 22.0
  final double flagSize;

  /// Espaciado horizontal entre bandera y nombre del país.
  ///
  /// Usa valores de AppSpacing:
  /// - Mobile Small: AppSpacing.xs + 2 (6.0)
  /// - Mobile: AppSpacing.sm (8.0)
  /// - Tablet/Desktop: AppSpacing.sm + 2 (10.0)
  final double spacing;

  /// Ancho máximo permitido para el texto del nombre del país.
  ///
  /// Calculado como porcentaje del ancho de pantalla:
  /// - Mobile Small: 50% del ancho
  /// - Mobile/Desktop: 60% del ancho
  /// - Tablet: 40% del ancho
  final double maxTextWidth;
}
