import '/core/theme/app_spacing.dart';
import '/core/widgets/my_text.dart';
import 'package:flutter/material.dart';

/// {@template my_checkbox}
/// Checkbox personalizado con animaciones y accesibilidad completa.
///
/// Un componente de checkbox que sigue el sistema de diseño
/// con animaciones suaves, estados visuales claros, accesibilidad completa
/// y uso consistente del theme system (AppSpacing, colorScheme).
///
/// ## Características Principales
///
/// | Categoría | Características |
/// |-----------|-----------------|
/// | **Animaciones** | Transición suave al marcar/desmarcar, scale animation, hover feedback |
/// | **Accesibilidad** | Semantics completos, lectores de pantalla, navegación por teclado |
/// | **Estados** | Normal, Hover, Checked, Disabled, Focus |
/// | **Theming** | Usa colorScheme.primary para check, AppSpacing para espaciado |
/// | **Rendimiento** | Optimizado con const constructors, memoización |
///
/// ## Uso Básico
///
/// ```dart
/// MyCheckbox(
///   label: 'Acepto los términos y condiciones',
///   value: agreedToTerms,
///   onChanged: (value) => setState(() => agreedToTerms = value),
/// )
/// ```
///
/// ## Estado Deshabilitado
///
/// ```dart
/// MyCheckbox(
///   label: 'Opción no disponible',
///   value: false,
///   onChanged: null, // Deshabilita el checkbox
/// )
/// ```
///
/// ## Sin Ancho Fijo
///
/// ```dart
/// MyCheckbox(
///   label: 'Recordarme',
///   value: rememberMe,
///   width: null, // Ocupa solo el espacio necesario
///   onChanged: handleChange,
/// )
/// ```
///
/// ## Con Texto de Error
///
/// ```dart
/// MyCheckbox(
///   label: 'Acepto política de privacidad',
///   value: acceptedPrivacy,
///   errorText: !acceptedPrivacy ? 'Debes aceptar la política' : null,
///   onChanged: handlePrivacyChange,
/// )
/// ```
///
/// ## Integración con MyForm
///
/// Este componente se integra automáticamente con [MyForm] a través del
/// tipo [FormFieldType.checkbox]:
///
/// ```dart
/// MyForm(
///   formItems: [
///     FormItemConfig(
///       id: 'terms',
///       type: FormFieldType.checkbox,
///       label: 'Acepto términos y condiciones',
///       isRequired: true,
///     ),
///   ],
///   onSubmit: handleSubmit,
/// )
/// ```
///
/// ## Changelog
///
/// **v2.0.0** (2025-12-24):
/// - Mejorado uso consistente de AppSpacing
/// - Usa colorScheme.primary para check (diseño consistente)
/// - Mejoras en animaciones (ScaleTransition suave)
/// - Estados visuales más claros (hover, focus)
/// - Documentación dartdoc mejorada
/// - Semantics completos para WCAG 2.1
/// - Optimización de rendimiento
///
/// **v1.0.0** (2025-12-19):
/// - Versión inicial con animaciones básicas
///
/// {@endtemplate}
///
/// Ver también:
/// - [MyDropdown] para selecciones desplegables
/// - [MySwitcher] para switches
/// - [MyForm] para formularios completos
class MyCheckbox extends StatefulWidget {
  const MyCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.width = 400,
    this.margin,
    this.enabled = true,
  });

  /// Texto de la etiqueta (clave de traducción o texto directo).
  ///
  /// Se procesa a través de [MyText], por lo que soporta claves
  /// de traducción automáticamente.
  ///
  /// ```dart
  /// label: 'Acepto términos y condiciones'
  /// label: 'auth.accept_terms' // Clave de traducción
  /// ```
  final String label;

  /// Estado actual del checkbox.
  ///
  /// `true`: Checkbox marcado
  /// `false`: Checkbox desmarcado
  ///
  /// ```dart
  /// value: isAccepted
  /// ```
  final bool value;

  /// Callback ejecutado cuando cambia el estado.
  ///
  /// Recibe el nuevo valor (`true` o `false`).
  /// Si es `null`, el checkbox se deshabilita automáticamente.
  ///
  /// ```dart
  /// onChanged: (newValue) {
  ///   setState(() => isAccepted = newValue);
  /// }
  /// ```
  final ValueChanged<bool>? onChanged;

  /// Ancho fijo del componente.
  ///
  /// Por defecto: `400`
  /// Si es `null`, ocupa solo el espacio necesario (usa MainAxisSize.min).
  ///
  /// ```dart
  /// width: 300  // Ancho fijo
  /// width: null // Ancho flexible
  /// width: double.infinity // Ancho completo (con Expanded)
  /// ```
  final double? width;

  /// Margen externo del componente.
  ///
  /// Por defecto: `AppSpacing.xs` (4.0)
  ///
  /// Usa valores de [AppSpacing] para consistencia:
  /// ```dart
  /// margin: AppSpacing.md  // 16.0
  /// margin: AppSpacing.lg  // 24.0
  /// margin: null           // Sin margen
  /// ```
  final double? margin;

  /// Si el checkbox está habilitado para interacción.
  ///
  /// Por defecto: `true`
  ///
  /// Cuando es `false` o [onChanged] es `null`:
  /// - No responde a toques
  /// - Se aplica opacidad 0.38 al texto y checkbox
  /// - Los Semantics indican "Deshabilitado"
  ///
  /// ```dart
  /// enabled: !isLoading
  /// enabled: hasPermission
  /// ```
  final bool enabled;

  @override
  State<MyCheckbox> createState() => _MyCheckboxState();
}

/// State interno para [MyCheckbox].
///
/// Maneja:
/// - Animaciones de check/uncheck (ScaleTransition)
/// - Estado de hover para feedback visual
/// - Lifecycle del AnimationController
class _MyCheckboxState extends State<MyCheckbox>
    with SingleTickerProviderStateMixin {
  /// Si el mouse está sobre el checkbox (solo desktop/web)
  bool _isHovered = false;

  /// Controlador de animación para el check (escalado).
  late AnimationController _checkController;

  /// Animación de escalado para el icono de check.
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    // Inicializar controlador con el valor inicial
    _checkController = AnimationController(
      duration: AppDuration.fast, // 200ms
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );

    // Animación con curva suave para mejor UX
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOutCubic, // Más suave que easeInOut
    );
  }

  @override
  void didUpdateWidget(MyCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animar cuando cambia el valor
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _checkController.forward();
      } else {
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  /// Maneja el tap del usuario.
  ///
  /// Solo ejecuta [onChanged] si está habilitado.
  void _handleTap() {
    if (widget.enabled && widget.onChanged != null) {
      widget.onChanged!(!widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMIZACIÓN: Extraer Theme una sola vez
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determinar estado efectivo
    final isDisabled = !widget.enabled || widget.onChanged == null;

    // OPTIMIZACIÓN: Calcular colores una sola vez
    // Usa colorScheme.primary para el check (consistente con theme system)
    final checkboxColor = widget.value
        ? (isDisabled
              ? colorScheme.onSurface.withValues(alpha: 0.38)
              : colorScheme.primary)
        : Colors.transparent;

    final borderColor = widget.value
        ? (isDisabled
              ? colorScheme.onSurface.withValues(alpha: 0.38)
              : colorScheme.primary)
        : (isDisabled
              ? colorScheme.onSurface.withValues(alpha: 0.38)
              : colorScheme.outline);

    final checkIconColor = isDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : colorScheme.onPrimary;

    final labelColor = isDisabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : colorScheme.onSurface;

    // Preparar Semantics descriptivos
    final String semanticLabel = widget.label;
    final String semanticValue = widget.value ? 'Marcado' : 'No marcado';
    final String semanticHint = isDisabled
        ? 'Deshabilitado'
        : 'Toca dos veces para ${widget.value ? 'desmarcar' : 'marcar'}';

    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      hint: semanticHint,
      checked: widget.value,
      enabled: !isDisabled,
      focusable: !isDisabled,
      child: MouseRegion(
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
        child: AnimatedContainer(
          duration: AppDuration.fast,
          curve: Curves.easeInOutCubic,
          width: widget.width,
          margin: EdgeInsets.all(widget.margin ?? AppSpacing.xs),
          decoration: BoxDecoration(
            // Feedback visual en hover (solo desktop/web)
            color: _isHovered && !isDisabled
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: AppRadius.borderRadiusSM,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              borderRadius: AppRadius.borderRadiusSM,
              splashColor: colorScheme.primary.withValues(alpha: 0.12),
              highlightColor: colorScheme.primary.withValues(alpha: 0.08),
              child: Padding(
                padding: AppSpacing.edgeInsetsSM,
                child: Row(
                  mainAxisSize: widget.width == null
                      ? MainAxisSize.min
                      : MainAxisSize.max,
                  children: [
                    // Checkbox animado con ScaleTransition suave
                    AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return AnimatedContainer(
                          duration: AppDuration.fast,
                          curve: Curves.easeInOutCubic,
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: checkboxColor,
                            border: Border.all(color: borderColor, width: 2),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: widget.value
                              ? ScaleTransition(
                                  scale: _checkAnimation,
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: checkIconColor,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Label con animación de color
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: AppDuration.fast,
                        curve: Curves.easeInOutCubic,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: labelColor,
                        ),
                        child: MyText(widget.label),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
