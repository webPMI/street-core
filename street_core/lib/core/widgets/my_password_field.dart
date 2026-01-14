import '/core/lang/context_tr.dart';
import '/core/lang/locale_keys.dart';
import '/core/theme/app_spacing.dart';
import 'my_text.dart';
import 'my_text_form_field.dart';
import 'package:flutter/material.dart';

class MyPasswordField extends StatefulWidget {
  const MyPasswordField({
    super.key,
    required this.controller,
    this.isNew = false,
    this.isRepeat = false,
    this.margin,
    this.pass,
    this.canShowPass = true,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.textInputAction,
    this.icon,
    this.showStrengthIndicator = false,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════
  final bool isNew;

  final TextEditingController controller;

  final bool isRepeat;

  final double? margin;

  final TextEditingController? pass;

  final bool canShowPass;

  final ValueChanged<String>? onChanged;

  /// ```
  final ValueChanged<String>? onFieldSubmitted;

  /// ```
  final FocusNode? focusNode;

  /// ```
  final TextInputAction? textInputAction;

  final Widget? icon;

  final bool showStrengthIndicator;

  @override
  State<MyPasswordField> createState() => _MyPasswordFieldState();
}

class _MyPasswordFieldState extends State<MyPasswordField>
    with SingleTickerProviderStateMixin {
  bool _obscurePass = true;
  String _errorText = '';
  late AnimationController _toggleController;
  late Animation<double> _iconRotation;
  late Animation<double> _iconOpacity;

  @override
  void initState() {
    super.initState();

    // Controlador de animación para toggle de visibilidad
    _toggleController = AnimationController(
      duration: AppDuration.fast, // 200ms
      vsync: this,
    );

    // Animación de rotación del icono (0° → 180°)
    _iconRotation =
        Tween<double>(
          begin: 0.0,
          end: 0.5, // 0.5 turns = 180 grados
        ).animate(
          CurvedAnimation(parent: _toggleController, curve: Curves.easeInOut),
        );

    // Animación de fade del icono (sutil)
    _iconOpacity = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _toggleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _toggleController.dispose();
    super.dispose();
  }

  /// Alterna la visibilidad de la contraseña con animación.
  ///
  /// Solo funciona si [canShowPass] es `true`.
  void _togglePasswordVisibility() {
    if (!widget.canShowPass) return;

    setState(() {
      _obscurePass = !_obscurePass;
      if (_obscurePass) {
        _toggleController.reverse();
      } else {
        _toggleController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMIZACIÓN: Extraer Theme una sola vez
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = widget.isRepeat ? LocaleKeys.repeatPassword : LocaleKeys.password;

    // Determinar estado de habilitación del botón de visibilidad
    final bool canToggleVisibility = widget.canShowPass;

    return Semantics(
      label: widget.isNew
          ? context.tr(LocaleKeys.newPasswordField)
          : widget.isRepeat
          ? context.tr(LocaleKeys.repeatPasswordField)
          : context.tr(LocaleKeys.passwordField),
      hint: context.tr(LocaleKeys.passwordField),
      enabled: true,
      textField: true,
      obscured: _obscurePass,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyTextFormField(
            maxLength: 64,
            textInputAction: widget.textInputAction,
            focusNode: widget.focusNode,
            onFieldSubmitted: widget.onFieldSubmitted,
            onChanged: widget.onChanged,
            margin: widget.margin,
            autofillHints: const [
              AutofillHints.password,
              AutofillHints.newPassword,
            ],
            hint: label,
            label: label,
            icon: widget.icon,
            sufIcon: AnimatedBuilder(
              animation: Listenable.merge([_iconRotation, _iconOpacity]),
              builder: (context, child) {
                // Determinar color del icono con animación
                final iconColor = _obscurePass
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary;

                return Semantics(
                  button: true,
                  enabled: canToggleVisibility,
                  label: _obscurePass
                      ? context.tr(LocaleKeys.showPassword)
                      : context.tr(LocaleKeys.hidePassword),
                  child: IconButton(
                    onPressed: canToggleVisibility
                        ? _togglePasswordVisibility
                        : null,
                    icon: FadeTransition(
                      opacity: _iconOpacity,
                      child: RotationTransition(
                        turns: _iconRotation,
                        child: Icon(
                          _obscurePass
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: canToggleVisibility
                              ? iconColor
                              : colorScheme.onSurface.withValues(alpha: 0.38),
                          size: AppIconSize.sm,
                        ),
                      ),
                    ),
                    tooltip: canToggleVisibility
                        ? (_obscurePass
                              ? context.tr(LocaleKeys.showPassword)
                              : context.tr(LocaleKeys.hidePassword))
                        : null,
                    splashRadius: 20,
                  ),
                );
              },
            ),
            controller: widget.controller,
            obscureText: _obscurePass,
            showValidationIcon: false, // No mostrar check en passwords
            validator: (String? value) {
              // Limpiar error previo
              setState(() {
                _errorText = '';
              });

              // Validar campo vacío
              if (value == null || value.isEmpty) {
                return context.tr(LocaleKeys.writeYourPassword);
              }

              // Validar repetición de contraseña
              if (widget.isRepeat) {
                if (widget.pass == null) {
                  return context.tr(LocaleKeys.originalPasswordNotProvided);
                }
                if (widget.controller.text.trim() != widget.pass!.text.trim()) {
                  return context.tr(LocaleKeys.passwordsDontMatch);
                }
                return null; // Validación exitosa para repetición
              }

              // Validar requisitos de seguridad (solo para contraseña original)
              final passwordRegex = RegExp(
                r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$',
              );

              if (!passwordRegex.hasMatch(value)) {
                setState(() {
                  _errorText = context.tr(LocaleKeys.passwordRequirements);
                });
                return context.tr(LocaleKeys.changeYourPassword);
              }

              return null; // Validación exitosa
            },
            isRequired: false,
          ),

          // Mensaje de requisitos de contraseña
          if (_errorText.isNotEmpty)
            Semantics(
              liveRegion: true,
              child: AnimatedContainer(
                duration: AppDuration.fast,
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                padding: AppSpacing.edgeInsetsSM,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: AppRadius.borderRadiusSM,
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: AppIconSize.xs,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: MyText(
                        _errorText,
                        fontSize: 12,
                        color: colorScheme.error,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Indicador de fuerza de contraseña (opcional)
          if (widget.showStrengthIndicator && !widget.isRepeat)
            _buildStrengthIndicator(),
        ],
      ),
    );
  }

  /// Construye el indicador de fuerza de contraseña.
  ///
  /// Muestra una barra de progreso animada con:
  /// - Color rojo para contraseñas débiles (< 30%)
  /// - Color naranja para contraseñas medias (30-60%)
  /// - Color verde para contraseñas fuertes (> 60%)
  Widget _buildStrengthIndicator() {
    final password = widget.controller.text;
    final strength = _calculatePasswordStrength(password);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determinar color y etiqueta según la fuerza
    final Color strengthColor;
    final String strengthLabel;
    final IconData strengthIcon;

    if (strength < 0.3) {
      strengthColor = colorScheme.error;
      strengthLabel = LocaleKeys.passwordWeak;
      strengthIcon = Icons.warning_rounded;
    } else if (strength < 0.6) {
      // Naranja no está en colorScheme, usar un tono intermedio
      strengthColor = Color.lerp(colorScheme.error, Colors.green, 0.5)!;
      strengthLabel = LocaleKeys.passwordMedium;
      strengthIcon = Icons.shield_outlined;
    } else {
      strengthColor = Colors.green; // Color success
      strengthLabel = LocaleKeys.passwordStrong;
      strengthIcon = Icons.verified_user_rounded;
    }

    return Semantics(
      label: context.tr(LocaleKeys.passwordStrengthIndicator),
      value: '${(strength * 100).toInt()}%',
      child: AnimatedContainer(
        duration: AppDuration.normal,
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: AppSpacing.edgeInsetsSM,
        decoration: BoxDecoration(
          color: strengthColor.withValues(alpha: 0.1),
          borderRadius: AppRadius.borderRadiusSM,
          border: Border.all(
            color: strengthColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono animado según fuerza
                TweenAnimationBuilder<double>(
                  duration: AppDuration.normal,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Icon(
                        strengthIcon,
                        size: AppIconSize.xs,
                        color: strengthColor,
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: AppDuration.normal,
                    tween: Tween(begin: 0.0, end: strength),
                    curve: Curves.easeInOutCubic,
                    builder: (context, value, child) {
                      return ClipRRect(
                        borderRadius: AppRadius.borderRadiusXS,
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            strengthColor,
                          ),
                          minHeight: 6,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                MyText(
                  strengthLabel,
                  fontSize: 12,
                  color: strengthColor,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Calcula la fuerza de una contraseña en una escala de 0.0 a 1.0.
  ///
  /// La fuerza se basa en los siguientes criterios:
  ///
  /// | Criterio | Puntuación |
  /// |----------|------------|
  /// | Longitud >= 8 caracteres | +0.20 |
  /// | Longitud >= 12 caracteres | +0.10 |
  /// | Contiene mayúsculas (A-Z) | +0.20 |
  /// | Contiene minúsculas (a-z) | +0.20 |
  /// | Contiene números (0-9) | +0.15 |
  /// | Contiene caracteres especiales (#?!@$%^&*-) | +0.15 |
  ///
  /// **Total máximo**: 1.0 (100%)
  ///
  /// ## Categorías de fuerza:
  /// - **Débil** (0.0 - 0.3): Falta algún requisito importante
  /// - **Media** (0.3 - 0.6): Cumple requisitos básicos
  /// - **Fuerte** (0.6 - 1.0): Cumple todos los requisitos
  ///
  /// Ejemplo:
  /// ```dart
  /// _calculatePasswordStrength('abc');       // 0.2 (Débil)
  /// _calculatePasswordStrength('Abc12345');  // 0.75 (Fuerte)
  /// _calculatePasswordStrength('Abc123!@');  // 1.0 (Fuerte)
  /// ```
  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0.0;

    // Criterio 1: Longitud mínima (8+ caracteres)
    if (password.length >= 8) {
      strength += 0.2;
    }

    // Criterio 2: Longitud recomendada (12+ caracteres)
    if (password.length >= 12) {
      strength += 0.1;
    }

    // Criterio 3: Contiene al menos una mayúscula
    if (RegExp(r'[A-Z]').hasMatch(password)) {
      strength += 0.2;
    }

    // Criterio 4: Contiene al menos una minúscula
    if (RegExp(r'[a-z]').hasMatch(password)) {
      strength += 0.2;
    }

    // Criterio 5: Contiene al menos un número
    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength += 0.15;
    }

    // Criterio 6: Contiene al menos un carácter especial
    if (RegExp(r'[#?!@$%^&*-]').hasMatch(password)) {
      strength += 0.15;
    }

    // Asegurar que el valor esté entre 0.0 y 1.0
    return strength.clamp(0.0, 1.0);
  }
}
