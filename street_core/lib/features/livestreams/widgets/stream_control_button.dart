// lib/features/livestreams/widgets/stream_control_button.dart

import 'package:flutter/material.dart';
import 'package:street_core/core/lang/context_tr.dart';
import 'package:street_core/core/lang/locale_keys.dart';
import 'package:street_core/core/theme/app_spacing.dart';

/// Reusable stream control button
///
/// Usage:
/// ```dart
/// StreamControlButton(
///   icon: Icons.play_arrow,
///   label: 'Iniciar',
///   onPressed: () => startStream(),
/// )
///
/// StreamControlButton.start(onPressed: () => startStream())
/// StreamControlButton.end(onPressed: () => endStream())
/// ```
class StreamControlButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? labelKey;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final bool isLoading;
  final bool isCompact;

  const StreamControlButton({
    super.key,
    required this.icon,
    this.label,
    this.labelKey,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.isLoading = false,
    this.isCompact = false,
  }) : assert(label != null || labelKey != null);

  /// Start button
  factory StreamControlButton.start({
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isCompact = false,
  }) {
    return StreamControlButton(
      icon: Icons.play_arrow,
      labelKey: LocaleKeys.start,
      onPressed: onPressed,
      color: Colors.white,
      backgroundColor: Colors.green,
      isLoading: isLoading,
      isCompact: isCompact,
    );
  }

  /// End button
  factory StreamControlButton.end({
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isCompact = false,
  }) {
    return StreamControlButton(
      icon: Icons.stop,
      labelKey: LocaleKeys.end,
      onPressed: onPressed,
      color: Colors.white,
      backgroundColor: Colors.red,
      isLoading: isLoading,
      isCompact: isCompact,
    );
  }

  /// Cancel button
  factory StreamControlButton.cancel({
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isCompact = false,
  }) {
    return StreamControlButton(
      icon: Icons.cancel,
      labelKey: LocaleKeys.cancel,
      onPressed: onPressed,
      color: Colors.white,
      backgroundColor: Colors.orange,
      isLoading: isLoading,
      isCompact: isCompact,
    );
  }

  /// Settings button
  factory StreamControlButton.settings({
    required VoidCallback? onPressed,
    bool isCompact = false,
  }) {
    return StreamControlButton(
      icon: Icons.settings,
      labelKey: LocaleKeys.settings,
      onPressed: onPressed,
      isCompact: isCompact,
    );
  }

  /// Share button
  factory StreamControlButton.share({
    required VoidCallback? onPressed,
    bool isCompact = false,
  }) {
    return StreamControlButton(
      icon: Icons.share,
      labelKey: LocaleKeys.share,
      onPressed: onPressed,
      isCompact: isCompact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? Theme.of(context).colorScheme.onPrimary;
    final btnBgColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final displayLabel = label ?? context.tr(labelKey!);

    if (isCompact) {
      return IconButton(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(btnColor),
                ),
              )
            : Icon(icon, color: btnColor),
        color: btnBgColor,
        tooltip: displayLabel,
      );
    }

    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(btnColor),
              ),
            )
          : Icon(icon, color: btnColor),
      label: Text(
        displayLabel,
        style: TextStyle(color: btnColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: btnBgColor,
        foregroundColor: btnColor,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

/// Control bar with multiple buttons
///
/// Usage:
/// ```dart
/// StreamControlBar(
///   buttons: [
///     StreamControlButton.start(onPressed: () => start()),
///     StreamControlButton.settings(onPressed: () => showSettings()),
///   ],
/// )
/// ```
class StreamControlBar extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment alignment;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const StreamControlBar({
    super.key,
    required this.buttons,
    this.alignment = MainAxisAlignment.spaceEvenly,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(AppSpacing.md),
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            )
          : null,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: alignment,
          children: buttons,
        ),
      ),
    );
  }
}

/// Floating action button for quick controls
///
/// Usage:
/// ```dart
/// StreamFloatingButton(
///   icon: Icons.videocam,
///   onPressed: () => toggleCamera(),
///   backgroundColor: Colors.red,
/// )
/// ```
class StreamFloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final bool mini;

  const StreamFloatingButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      tooltip: tooltip,
      mini: mini,
      child: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
