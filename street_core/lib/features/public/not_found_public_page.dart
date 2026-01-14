import 'package:street_core/data/app_icon.dart';

import '../../../core/helpers/responsive/responsive_builder.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/lang/locale_keys.dart';
import '../../core/widgets/my_text.dart';

/// 404 Page for Public Layout (unauthenticated users)
///
/// Features:
/// - Fun and engaging design
/// - Animated motorcycle icon
/// - Gradient background using theme colors
/// - Responsive design (mobile, tablet, desktop)
/// - Humorous messaging aligned with FitRiders brand
/// - Compatible with all 8 theme variants
class NotFoundPublicPage extends StatefulWidget {
  const NotFoundPublicPage({super.key});

  @override
  State<NotFoundPublicPage> createState() => _NotFoundPublicPageState();
}

class _NotFoundPublicPageState extends State<NotFoundPublicPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.error_outline),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.appTitle),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : (isTablet ? 48 : 64),
              vertical: 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotateAnimation.value,
                        child: Icon(
                          appIconData,
                          size: isMobile ? 120 : (isTablet ? 150 : 180),
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: isMobile ? 24 : 32),

                // 404 Code
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: MyText(
                        '404',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: isMobile ? 80 : (isTablet ? 100 : 120),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: isMobile ? 16 : 24),

                // Title
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1400),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: MyText(
                          LocaleKeys.pageNotFound,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: isMobile ? 24 : (isTablet ? 28 : 32),
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: isMobile ? 12 : 16),

                // Fun Message
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 32,
                          ),
                          child: MyText(
                            LocaleKeys.pageNotFoundMessage,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: isMobile ? 14 : 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: isMobile ? 32 : 48),

                // Back to Home Button
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: _BackToHomeButton(
                          onPressed: () => context.go('/'),
                          isMobile: isMobile,
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: isMobile ? 24 : 32),

                // Subtle decorative elements
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 2000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value * 0.6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_bike,
                            size: isMobile ? 24 : 32,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.sports_motorsports,
                            size: isMobile ? 24 : 32,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.directions_run,
                            size: isMobile ? 24 : 32,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BACK TO HOME BUTTON
// ============================================================================

class _BackToHomeButton extends StatefulWidget {
  const _BackToHomeButton({required this.onPressed, required this.isMobile});

  final VoidCallback onPressed;
  final bool isMobile;

  @override
  State<_BackToHomeButton> createState() => _BackToHomeButtonState();
}

class _BackToHomeButtonState extends State<_BackToHomeButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? Matrix4.diagonal3Values(1.05, 1.05, 1.0)
            : Matrix4.identity(),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: const Icon(Icons.home_rounded),
          label: MyText(LocaleKeys.backToHome),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isMobile ? 24 : 32,
              vertical: widget.isMobile ? 14 : 18,
            ),
            backgroundColor: Colors.white,
            foregroundColor: theme.colorScheme.primary,
            elevation: _isHovered ? 8 : 4,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: TextStyle(
              fontSize: widget.isMobile ? 14 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
