import 'package:flutter/material.dart';
import '../../lang/context_tr.dart';
import '/core/theme/app_spacing.dart';

/// Animated navigation button with smooth hover effects and multiple visual states.
///
/// A highly interactive button designed for navigation menus that provides visual
/// feedback through scale animations, color transitions, and ripple effects.
///
/// ## Features
///
/// - **Scale Animation**: Subtle zoom on hover (1.0 → 1.05)
/// - **Color Transitions**: Smooth background color changes
/// - **Active State**: Visual highlighting for current route
/// - **Pressed State**: Immediate visual feedback on tap
/// - **Accessibility**: Full Semantics support for screen readers
/// - **Theme Integration**: Uses colorScheme from theme
/// - **Design System**: Uses AppSpacing and AppRadius constants
///
/// ## Visual States
///
/// 1. **Normal**: Transparent background, no scale
/// 2. **Hover**: Primary color with 5% opacity, scale 1.05
/// 3. **Pressed**: Primary color with 15% opacity, scale 0.98
/// 4. **Active**: Primary color with 10% opacity, border outline
///
/// ## Usage
///
/// ### Basic Navigation Button
/// ```dart
/// AnimatedNavButton(
///   isActive: currentRoute == '/home',
///   onPressed: () => router.go('/home'),
///   label: 'Home',
///   child: Row(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       Icon(Icons.home),
///       SizedBox(width: AppSpacing.sm),
///       Text('Home'),
///     ],
///   ),
/// )
/// ```
///
/// ### With Icon Only (Mobile)
/// ```dart
/// AnimatedNavButton(
///   isActive: false,
///   onPressed: () => showProfile(),
///   label: 'Profile',
///   child: Icon(Icons.person),
/// )
/// ```
///
/// ### Disabled State
/// ```dart
/// AnimatedNavButton(
///   isActive: false,
///   onPressed: null, // Disables button
///   label: 'Coming Soon',
///   child: Text('Coming Soon'),
/// )
/// ```
///
/// ### In Drawer Menu
/// ```dart
/// ListView(
///   children: [
///     AnimatedNavButton(
///       isActive: currentRoute == '/dashboard',
///       onPressed: () => router.go('/dashboard'),
///       label: 'Dashboard',
///       child: ListTile(
///         leading: Icon(Icons.dashboard),
///         title: Text('Dashboard'),
///       ),
///     ),
///     // More navigation items...
///   ],
/// )
/// ```
///
/// ## Design System Integration
///
/// - **Spacing**: Uses AppSpacing.md (horizontal), AppSpacing.sm (vertical)
/// - **Border Radius**: Uses AppRadius.sm (8.0)
/// - **Animation**: Uses AppDuration.fast (200ms)
/// - **Colors**: Uses theme.colorScheme.primary with various opacities
///
/// ## Animation Details
///
/// - **Hover Duration**: 200ms with easeInOut curve
/// - **Scale Range**: 1.0 (normal) to 1.05 (hover) to 0.98 (pressed)
/// - **Color Transition**: 200ms with easeInOut curve
///
/// ## Accessibility
///
/// Includes Semantics widget with:
/// - `button: true` - Identifies as button for screen readers
/// - `enabled: onPressed != null` - Indicates interactive state
/// - `label: label` - Provides text description for screen readers
///
/// ## See Also
///
/// - [AnimatedPrimaryButton] - For primary action buttons
/// - [AppSpacing] - Spacing constants
/// - [AppRadius] - Border radius constants
/// - [AppDuration] - Animation duration constants
class AnimatedNavButton extends StatefulWidget {
  /// Creates an animated navigation button.
  ///
  /// The [child] and [label] parameters must not be null.
  /// The [label] is used for accessibility purposes.
  const AnimatedNavButton({
    super.key,
    required this.isActive,
    this.onPressed,
    required this.child,
    this.label,
  });

  /// Whether this button represents the currently active route.
  ///
  /// When `true`, the button displays with a background color and border
  /// to indicate it's the current selection.
  final bool isActive;

  /// Callback invoked when the button is pressed.
  ///
  /// If `null`, the button is disabled and won't respond to interactions.
  /// The button cursor will change to [SystemMouseCursors.basic] when disabled.
  final VoidCallback? onPressed;

  /// The widget to display inside the button.
  ///
  /// Typically a [Row] containing an [Icon] and [Text], but can be any widget.
  /// Common patterns:
  /// - `Row(children: [Icon(...), SizedBox(width: 8), Text(...)])`
  /// - `Icon(...)` (icon-only for mobile)
  /// - `ListTile(leading: Icon(...), title: Text(...))`
  final Widget child;

  /// Semantic label for accessibility.
  ///
  /// This text is read by screen readers to describe the button's purpose.
  /// Should be descriptive, e.g., "Navigate to Home page".
  final String? label;

  @override
  State<AnimatedNavButton> createState() => _AnimatedNavButtonState();
}

class _AnimatedNavButtonState extends State<AnimatedNavButton>
    with SingleTickerProviderStateMixin {
  // Visual state tracking
  bool _isHovering = false;
  bool _isPressed = false;

  // Animation controller
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  // Animation constants
  static const Duration _animationDuration = AppDuration.fast;
  static const Curve _animationCurve = Curves.easeInOut;

  // Scale values for different states
  static const double _scaleNormal = 1.0;
  static const double _scaleHover = 1.05;
  static const double _scalePressed = 0.98;

  // Opacity values for background colors
  static const double _opacityActive = 0.1;
  static const double _opacityHover = 0.05;
  static const double _opacityPressed = 0.15;
  static const double _opacityBorder = 0.3;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  /// Initialize animation controller and scale animation.
  void _initializeAnimations() {
    _hoverController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _scaleAnimation = Tween<double>(begin: _scaleNormal, end: _scaleHover)
        .animate(
          CurvedAnimation(parent: _hoverController, curve: _animationCurve),
        );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  /// Handle mouse enter event.
  void _onMouseEnter() {
    if (widget.onPressed != null && !_isPressed) {
      setState(() => _isHovering = true);
      _hoverController.forward();
    }
  }

  /// Handle mouse exit event.
  void _onMouseExit() {
    setState(() => _isHovering = false);
    if (!_isPressed) {
      _hoverController.reverse();
    }
  }

  /// Handle tap down event (pressed state).
  void _onTapDown() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  /// Handle tap up/cancel event (release pressed state).
  void _onTapUp() {
    setState(() => _isPressed = false);
    if (!_isHovering) {
      _hoverController.reverse();
    }
  }

  /// Calculate the appropriate background color based on current state.
  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (widget.isActive) {
      return colorScheme.primary.withValues(alpha: _opacityActive);
    }
    if (_isPressed) {
      return colorScheme.primary.withValues(alpha: _opacityPressed);
    }
    if (_isHovering) {
      return colorScheme.primary.withValues(alpha: _opacityHover);
    }
    return Colors.transparent;
  }

  /// Calculate the appropriate scale based on current state.
  double _getScale() {
    if (_isPressed) {
      return _scalePressed;
    }
    return _scaleAnimation.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEnabled = widget.onPressed != null;

    return Semantics(
      button: widget.onPressed != null,
      enabled: isEnabled,
      label: context.tr(widget.label ?? ''),
      child: MouseRegion(
        onEnter: (_) => _onMouseEnter(),
        onExit: (_) => _onMouseExit(),
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _getScale(),
              child: AnimatedContainer(
                duration: _animationDuration,
                curve: _animationCurve,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(colorScheme),
                  borderRadius: AppRadius.borderRadiusSM,
                  border: widget.isActive
                      ? Border.all(
                          color: colorScheme.primary.withValues(
                            alpha: _opacityBorder,
                          ),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    onTapDown: (_) => _onTapDown(),
                    onTapUp: (_) => _onTapUp(),
                    onTapCancel: _onTapUp,
                    borderRadius: AppRadius.borderRadiusSM,
                    hoverColor: Colors.transparent,
                    splashColor: colorScheme.primary.withValues(
                      alpha: _opacityActive,
                    ),
                    highlightColor: colorScheme.primary.withValues(
                      alpha: _opacityHover,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
