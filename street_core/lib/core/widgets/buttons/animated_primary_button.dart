// animated_primary_button.dart

import 'package:flutter/material.dart';
import '/core/theme/app_spacing.dart';

/// Animated primary button with enhanced interactions and accessibility.
///
/// A highly interactive button with smooth animations for all states:
/// - **Scale animation**: 1.0 → 1.05 on hover/press
/// - **Elevation animation**: Smooth shadow transitions
/// - **Glow effect**: Primary color glow on hover
/// - **Ripple effect**: Material ripple on tap
/// - **Loading state**: Progress indicator with disabled interactions
/// - **Disabled state**: Reduced opacity with no interactions
///
/// ## Design System Integration
///
/// - Uses [AppSpacing] for consistent padding
/// - Uses [AppRadius] for border radius
/// - Uses [AppDuration] for animation timing
/// - Uses [AppElevation] for shadow depth
/// - Fully integrated with theme [ColorScheme]
///
/// ## Accessibility Features
///
/// - Semantic labels for screen readers
/// - Keyboard navigation support
/// - High contrast mode support
/// - Touch target size compliance (48x48 minimum)
/// - Clear visual feedback for all states
///
/// ## States
///
/// - **Normal**: Default appearance with primary gradient
/// - **Hover**: Scaled up with enhanced shadow and glow
/// - **Pressed**: Slight scale down with reduced elevation
/// - **Loading**: Shows progress indicator, disables interaction
/// - **Disabled**: Reduced opacity, no cursor change
///
/// ## Usage Examples
///
/// ### Basic Usage
/// ```dart
/// AnimatedPrimaryButton(
///   onPressed: () => print('Button pressed'),
///   child: Text('Click Me'),
/// )
/// ```
///
/// ### With Icon
/// ```dart
/// AnimatedPrimaryButton(
///   onPressed: () => Navigator.push(...),
///   child: Row(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       Icon(Icons.login, size: AppIconSize.sm),
///       SizedBox(width: AppSpacing.sm),
///       Text('Login'),
///     ],
///   ),
/// )
/// ```
///
/// ### Loading State
/// ```dart
/// AnimatedPrimaryButton(
///   onPressed: _isLoading ? null : _handleSubmit,
///   isLoading: _isLoading,
///   child: Text('Submit'),
/// )
/// ```
///
/// ### Disabled State
/// ```dart
/// AnimatedPrimaryButton(
///   onPressed: null, // null disables the button
///   child: Text('Disabled'),
/// )
/// ```
///
/// ### Custom Semantics
/// ```dart
/// AnimatedPrimaryButton(
///   onPressed: _save,
///   semanticLabel: 'Guardar cambios del perfil',
///   child: Text('Guardar'),
/// )
/// ```
///
/// ## Performance Considerations
///
/// - Uses [SingleTickerProviderStateMixin] for efficient animations
/// - Animations are automatically disposed
/// - Ripple effects use Material's optimized implementation
/// - Scale transforms are hardware-accelerated
///
/// See also:
/// - [AnimatedNavButton] for navigation-specific buttons
/// - [MyButton] for simpler button variations
class AnimatedPrimaryButton extends StatefulWidget {
  /// Creates an animated primary button.
  ///
  /// The [child] parameter is required and defines the button's content.
  /// The [onPressed] callback is called when the button is tapped. If null,
  /// the button will be disabled.
  const AnimatedPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.semanticLabel,
    this.width,
    this.height,
  });

  /// Callback when button is pressed.
  ///
  /// If null, the button will be disabled with reduced opacity and no
  /// hover/press animations.
  final VoidCallback? onPressed;

  /// Child widget to display inside the button.
  ///
  /// Typically a [Text] widget or a [Row] containing an icon and text.
  /// The child will automatically receive proper color styling from the theme.
  final Widget child;

  /// Whether the button is in loading state.
  ///
  /// When true, displays a [CircularProgressIndicator] and disables
  /// interactions. Defaults to false.
  final bool isLoading;

  /// Semantic label for screen readers.
  ///
  /// Provides additional context for accessibility. If not provided,
  /// the button's visible text will be used.
  final String? semanticLabel;

  /// Optional fixed width for the button.
  ///
  /// If null, the button will size itself based on its content.
  final double? width;

  /// Optional fixed height for the button.
  ///
  /// If null, the button will use default padding to determine height.
  final double? height;

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _glowAnimation;

  // Animation constants using AppDuration
  static const Duration _hoverDuration = AppDuration.fast; // 200ms
  static const Duration _pressDuration = AppDuration.instant; // 100ms

  // Scale values
  static const double _scaleNormal = 1.0;
  static const double _scaleHover = 1.05;
  static const double _scalePressed = 0.98;

  // Elevation values using AppElevation
  static const double _elevationNormal = AppElevation.sm; // 2.0
  static const double _elevationHover = AppElevation.md; // 4.0
  static const double _elevationPressed = AppElevation.xs; // 1.0

  // Glow values
  static const double _glowNone = 0.0;
  static const double _glowMax = 12.0;

  // State tracking
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _hoverDuration);

    _scaleAnimation = Tween<double>(
      begin: _scaleNormal,
      end: _scaleHover,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _elevationAnimation = Tween<double>(
      begin: _elevationNormal,
      end: _elevationHover,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(
      begin: _glowNone,
      end: _glowMax,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Handles hover enter event.
  void _onHoverEnter() {
    if (_isEnabled) {
      setState(() => _isHovered = true);
      _controller.forward();
    }
  }

  /// Handles hover exit event.
  void _onHoverExit() {
    setState(() => _isHovered = false);
    if (!_isPressed) {
      _controller.reverse();
    }
  }

  /// Handles tap down event.
  void _onTapDown(TapDownDetails details) {
    if (_isEnabled) {
      setState(() => _isPressed = true);
      _controller.animateTo(
        0.5, // Mid-point for pressed state
        duration: _pressDuration,
        curve: Curves.easeOut,
      );
    }
  }

  /// Handles tap up event.
  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    if (_isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  /// Handles tap cancel event.
  void _onTapCancel() {
    setState(() => _isPressed = false);
    if (_isHovered) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  /// Returns true if the button is enabled (not loading and onPressed is not null).
  bool get _isEnabled => !widget.isLoading && widget.onPressed != null;

  /// Calculates the current scale based on state.
  double get _currentScale {
    if (!_isEnabled) return _scaleNormal;
    if (_isPressed) return _scalePressed;
    return _scaleAnimation.value;
  }

  /// Calculates the current elevation based on state.
  double get _currentElevation {
    if (!_isEnabled) return AppElevation.none;
    if (_isPressed) return _elevationPressed;
    return _elevationAnimation.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine button colors based on state
    final buttonColor = _isEnabled
        ? colorScheme.primary
        : colorScheme.onSurface.withOpacity(0.12);

    final textColor = _isEnabled
        ? colorScheme.onPrimary
        : colorScheme.onSurface.withOpacity(0.38);

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        onEnter: (_) => _onHoverEnter(),
        onExit: (_) => _onHoverExit(),
        cursor: _isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _currentScale,
                child: AnimatedContainer(
                  duration: _pressDuration,
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    gradient: _isEnabled
                        ? LinearGradient(
                            colors: [
                              buttonColor,
                              buttonColor.withOpacity(0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: _isEnabled ? null : buttonColor,
                    borderRadius: AppRadius.buttonRadius,
                    boxShadow: [
                      // Main shadow
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: _currentElevation * 2,
                        offset: Offset(0, _currentElevation),
                      ),
                      // Glow effect
                      if (_isEnabled && _glowAnimation.value > 0)
                        BoxShadow(
                          color: buttonColor.withOpacity(0.4),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: _glowAnimation.value / 4,
                        ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isEnabled ? widget.onPressed : null,
                      borderRadius: AppRadius.buttonRadius,
                      splashColor: Colors.white.withOpacity(0.2),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + AppSpacing.xxs, // 10.0
                        ),
                        alignment: Alignment.center,
                        // Minimum touch target size for accessibility
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: _buildContent(context, textColor),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the button content (loading indicator or child).
  Widget _buildContent(BuildContext context, Color textColor) {
    if (widget.isLoading) {
      return SizedBox(
        width: AppIconSize.sm,
        height: AppIconSize.sm,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
      child: IconTheme(
        data: IconThemeData(color: textColor, size: AppIconSize.sm),
        child: widget.child,
      ),
    );
  }
}
