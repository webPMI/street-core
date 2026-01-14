import '/core/helpers/responsive/responsive_builder.dart';
import '/core/theme/app_spacing.dart';
import '/core/widgets/my_text.dart';
import 'package:flutter/material.dart';

/// {@template my_switcher}
/// Switch personalizado con animaciones fluidas y accesibilidad completa.
///
/// Un componente de switch (interruptor) que sigue el sistema de diseño de FitRiders
/// con animaciones fluidas, estados visuales claros y accesibilidad completa.
///
/// ## Características Principales
///
/// | Categoría | Características |
/// |-----------|-----------------|
/// | **Animaciones** | Transición fluida con Curves.easeInOut, hover feedback, cambio de color |
/// | **Accesibilidad** | Semantics, estados claros, navegación por teclado, etiquetas descriptivas |
/// | **Estados** | Normal, Hover, Active, Disabled, Focus |
/// | **Rendimiento** | Optimizado con const constructors donde es posible |
/// | **Sistema de Diseño** | Usa AppSpacing, AppDuration, colorScheme.primary |
///
/// ## Uso Básico
///
/// ```dart
/// MySwitcher(
///   title: 'Notificaciones',
///   value: notificationsEnabled,
///   onChanged: (value) => setState(() => notificationsEnabled = value),
/// )
/// ```
///
/// ## Estado Deshabilitado
///
/// ```dart
/// MySwitcher(
///   title: 'Función premium',
///   value: false,
///   onChanged: null, // Deshabilita el switch
/// )
/// ```
///
/// ## Ancho Personalizado
///
/// ```dart
/// MySwitcher(
///   title: 'Modo oscuro',
///   value: darkMode,
///   width: 300,
///   onChanged: handleDarkModeChange,
/// )
/// ```
///
/// ## Estados Visuales
///
/// - **Normal**: Track transparente, borde visible, label normal
/// - **Hover**: Fondo sutil, animación 200ms
/// - **Activo**: Track colorScheme.primary, thumb colorScheme.onPrimary
/// - **Deshabilitado**: Colores atenuados (38% opacidad), cursor por defecto
/// - **Focus**: Overlay con colorScheme.primary (12% opacidad)
///
/// {@endtemplate}
class MySwitcher extends StatefulWidget {
  /// Crea un [MySwitcher] personalizado.
  ///
  /// Requiere [title], [value] y [onChanged]. Los demás parámetros son opcionales.
  const MySwitcher({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.width,
    this.margin,
    this.enabled = true,
  });

  /// Texto de la etiqueta (clave de traducción).
  ///
  /// Usado para [Semantics] y [MyText].
  final String title;

  /// Estado actual del switch.
  ///
  /// `true` para activo, `false` para inactivo.
  final bool value;

  /// Callback ejecutado cuando cambia el estado.
  ///
  /// Si es `null`, el switch se deshabilita automáticamente.
  /// Recibe el nuevo valor como parámetro.
  final ValueChanged<bool>? onChanged;

  /// Ancho del componente.
  ///
  /// Por defecto: 380 en móvil, 80% del ancho en tablet.
  final double? width;

  /// Margen externo.
  ///
  /// Por defecto: `AppSpacing.xs`.
  final double? margin;

  /// Si el switch está habilitado.
  ///
  /// Por defecto: `true`. Si `false` o `onChanged` es `null`, el switch se deshabilita.
  final bool enabled;

  @override
  State<MySwitcher> createState() => _MySwitcherState();
}

class _MySwitcherState extends State<MySwitcher> {
  bool _isHovered = false;

  /// Maneja el tap en el switch.
  void _handleTap() {
    if (widget.enabled && widget.onChanged != null) {
      widget.onChanged!(!widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDisabled = !widget.enabled || widget.onChanged == null;

    // Ancho responsivo
    final effectiveWidth =
        widget.width ?? (context.isTablet ? context.screenWidth * 0.8 : 380);

    return Semantics(
      label: widget.title,
      toggled: widget.value,
      enabled: !isDisabled,
      hint: isDisabled
          ? 'Deshabilitado'
          : (widget.value ? 'Toca para desactivar' : 'Toca para activar'),
      child: MouseRegion(
        cursor: isDisabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) {
          if (!isDisabled) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          if (_isHovered) {
            setState(() => _isHovered = false);
          }
        },
        child: GestureDetector(
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: AppDuration.fast,
            curve: Curves.easeInOut,
            width: effectiveWidth,
            margin: EdgeInsets.all(widget.margin ?? AppSpacing.xs),
            padding: AppSpacing.edgeInsetsMD,
            decoration: BoxDecoration(
              color: _isHovered && !isDisabled
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                  : Colors.transparent,
              borderRadius: AppRadius.borderRadiusSM,
              border: Border.all(
                color: isDisabled
                    ? colorScheme.outline.withValues(alpha: 0.38)
                    : colorScheme.outline.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Label con animación de color
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: AppDuration.fast,
                    curve: Curves.easeInOut,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: isDisabled
                          ? colorScheme.onSurface.withValues(alpha: 0.38)
                          : colorScheme.onSurface,
                    ),
                    child: MyText(widget.title),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Switch usando el tema global (AppTheme._buildSwitchTheme)
                Switch(
                  value: widget.value,
                  onChanged: isDisabled ? null : widget.onChanged,
                  // El Switch.adaptive usa automáticamente el SwitchTheme del AppTheme
                  // que ya define thumbColor y trackColor usando colorScheme.primary
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
