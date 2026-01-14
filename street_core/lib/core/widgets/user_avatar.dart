import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/helpers/responsive/responsive_builder.dart';

/// Avatar widget with cached image loading and fallback support.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.size,
    this.onTap,
    this.imageUrl,
    this.fallbackText,
    this.backgroundColor,
    this.textColor,
  });

  final double? size;
  final VoidCallback? onTap;
  final String? imageUrl;
  final String? fallbackText;
  final Color? backgroundColor;
  final Color? textColor;

  /// Check if URL is valid and not empty
  bool get _hasValidImage =>
      imageUrl != null &&
      imageUrl!.isNotEmpty &&
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  /// Get initials from fallback text
  String get _initials {
    if (fallbackText == null || fallbackText!.isEmpty) return '?';
    final parts = fallbackText!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fallbackText![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = context.isMobile;
    final radius = size ?? (isMobile ? 20.0 : 20.0);
    final bgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final fgColor = textColor ?? theme.colorScheme.onPrimaryContainer;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(100),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: _hasValidImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      radius: radius,
                      backgroundImage: imageProvider,
                    ),
                    placeholder: (context, url) => CircleAvatar(
                      radius: radius,
                      backgroundColor: bgColor,
                      child: SizedBox(
                        width: radius,
                        height: radius,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: fgColor,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildFallback(
                      radius: radius,
                      bgColor: bgColor,
                      fgColor: fgColor,
                    ),
                  )
                : _buildFallback(
                    radius: radius,
                    bgColor: bgColor,
                    fgColor: fgColor,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback({
    required double radius,
    required Color bgColor,
    required Color fgColor,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        _initials,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
