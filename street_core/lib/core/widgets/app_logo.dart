import 'package:flutter/material.dart';
import '../lang/context_tr.dart';
import '../lang/locale_keys.dart';
import '/core/theme/app_spacing.dart';
import '../../data/app_icon.dart';

class AppLogo extends StatefulWidget {
  const AppLogo({
    super.key,
    this.variant = LogoVariant.full,
    this.size,
    this.color,
    this.animate = false,
    this.animationType = LogoAnimationType.fadeIn,
    this.showText = false,
    this.text = 'app.title',
    this.semanticLabel,
    this.isCompact = false,
    this.icon,
    this.iconColor,
    this.padding,
    this.margin,
  });

  /// Visual variant of the logo
  final LogoVariant variant;

  /// Custom size (overrides variant default)
  final double? size, padding, margin;

  /// Custom color (overrides theme default)
  final Color? color;

  /// Whether to enable animation
  final bool animate;

  /// Type of animation to apply
  final LogoAnimationType animationType;

  /// Whether to show text alongside icon
  final bool showText;

  /// Text to display (when showText is true)
  final String text;

  /// Custom semantic label for accessibility
  final String? semanticLabel;

  /// Whether to use compact mode (affects size in some variants)
  final bool isCompact;
  final IconData? icon;
  final Color? iconColor;

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  IconData iconData = appIconData;
  @override
  void initState() {
    if (widget.icon != null) {
      iconData = widget.icon!;
    }
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    if (!widget.animate) return;

    _controller = AnimationController(
      duration: widget.animationType == LogoAnimationType.pulse
          ? AppDuration.verySlow
          : AppDuration.slow,
      vsync: this,
    );

    switch (widget.animationType) {
      case LogoAnimationType.pulse:
        _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        _controller.repeat(reverse: true);
        break;
      case LogoAnimationType.fadeIn:
        _animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
        _controller.forward();
        break;
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = widget.color ?? colorScheme.primary;
    final semanticLabel =
        widget.semanticLabel ??
        '${context.tr(widget.text)} - ${context.tr(LocaleKeys.appDescription)}';

    Widget logo;

    switch (widget.variant) {
      case LogoVariant.iconOnly:
        logo = _buildIconOnly(effectiveColor);
        break;
      case LogoVariant.horizontal:
        logo = _buildHorizontal(effectiveColor);
        break;
      case LogoVariant.vertical:
        logo = _buildVertical(effectiveColor);
        break;
      case LogoVariant.full:
        logo = _buildFull(context, effectiveColor);
        break;
    }

    // Wrap with animation if enabled
    if (widget.animate) {
      if (widget.animationType == LogoAnimationType.pulse) {
        logo = ScaleTransition(scale: _animation, child: logo);
      } else if (widget.animationType == LogoAnimationType.fadeIn) {
        logo = FadeTransition(opacity: _animation, child: logo);
      }
    }

    // Wrap with Semantics for accessibility
    return Semantics(label: semanticLabel, image: true, child: logo);
  }

  /// Build full variant: circular icon with shadow
  Widget _buildFull(BuildContext context, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = widget.size ?? AppIconSize.xxl;

    return Container(
      padding: widget.padding != null
          ? EdgeInsets.all(widget.padding!)
          : AppSpacing.edgeInsetsLG,
      margin: widget.margin != null
          ? EdgeInsets.all(widget.margin!)
          : AppSpacing.edgeInsetsLG,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: AppSpacing.lg,
            offset: const Offset(0, AppSpacing.sm),
          ),
        ],
      ),
      child: Icon(iconData, size: size, color: color),
    );
  }

  /// Build icon-only variant: simple icon
  Widget _buildIconOnly(Color color) {
    final size = widget.size ?? AppIconSize.lg;

    return Icon(iconData, size: size, color: color);
  }

  /// Build horizontal variant: icon + text side by side
  Widget _buildHorizontal(Color color) {
    final size = widget.size ?? AppIconSize.lg;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconData, size: size, color: color),
        if (widget.showText) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            widget.text,
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  /// Build vertical variant: icon above text
  Widget _buildVertical(Color color) {
    final size = widget.size ?? AppIconSize.xl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconData, size: size, color: color),
        if (widget.showText) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.text,
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

/// Logo layout variants
enum LogoVariant {
  /// Full circular logo with shadow and padding
  full,

  /// Simple icon without decoration
  iconOnly,

  /// Icon and text arranged horizontally
  horizontal,

  /// Icon and text arranged vertically
  vertical,
}

/// Logo animation types
enum LogoAnimationType {
  /// Continuous pulsing effect
  pulse,

  /// Single fade-in on mount
  fadeIn,
}
