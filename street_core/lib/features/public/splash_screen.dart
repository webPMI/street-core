import 'dart:async';

import 'package:street_core/core/widgets/app_logo.dart';

import '../../../config/env.dart';
import '../../../core/helpers/logger.dart';
import '../../../core/helpers/responsive/responsive_builder.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/router/navigation_service.dart';
import '../../../core/widgets/my_text.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/lang/locale_keys.dart';
import '../auth/bloc/auth_cubit.dart';
import '../auth/bloc/auth_state.dart';

/// Optimized splash screen with proper GoRouter navigation
///
/// Features:
/// - Responsive layout for all screen sizes
/// - Proper GoRouter navigation (not Navigator)
/// - Optimized performance (no unnecessary rebuilds)
/// - Clean animations without performance overhead
/// - Proper error handling with retry
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  String _statusMessage = LocaleKeys.initializing;
  bool _isLoading = true;
  bool _hasNavigated = false;
  Timer? _timeoutTimer;

  static const _minSplashDuration = Duration(milliseconds: 1500);
  static const _maxSplashDuration = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeSplash();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  Future<void> _initializeSplash() async {
    final startTime = DateTime.now();

    try {
      _updateStatus(LocaleKeys.checkingAuthentication);

      // Start auth check
      if (mounted) {
        context.read<AuthCubit>().initialize();
      }

      // Safety timeout - force navigation after max duration
      _timeoutTimer = Timer(_maxSplashDuration, () {
        if (mounted && !_hasNavigated) {
          AppLogger.warning('Splash timeout reached', tag: 'SplashScreen');
          _navigateToLogin();
        }
      });

      // Ensure minimum splash duration for smooth UX
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < _minSplashDuration) {
        await Future<void>.delayed(_minSplashDuration - elapsed);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Splash initialization failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'SplashScreen',
      );
      _updateStatus(LocaleKeys.errorInitializationFailed);
      // Navigate to login after error
      Future<void>.delayed(const Duration(seconds: 2), _navigateToLogin);
    }
  }

  void _updateStatus(String message) {
    if (!mounted) return;
    setState(() {
      _statusMessage = message;
      _isLoading = !message.contains('error') && !message.contains('ready');
    });
  }

  void _handleAuthState(AuthState state) {
    if (_hasNavigated || !mounted) return;

    if (state is AuthAuthenticated) {
      _updateStatus(LocaleKeys.authenticated);
      _navigateToDashboard();
    } else if (state is AuthUnauthenticated) {
      _updateStatus(LocaleKeys.unauthenticated);
      _navigateToLogin();
    } else if (state is AuthError) {
      _updateStatus(LocaleKeys.authFailed);
      Future<void>.delayed(const Duration(seconds: 1), _navigateToLogin);
    }
  }

  Future<void> _navigateToDashboard() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _timeoutTimer?.cancel();

    AppLogger.info('Navigating to dashboard', tag: 'SplashScreen');

    // Intentar restaurar la última ruta guardada
    final savedRoute = await NavigationService().getRoute();
    if (savedRoute != null && savedRoute.startsWith('/dashboard') && mounted) {
      AppLogger.info('Restoring saved route: $savedRoute', tag: 'SplashScreen');
      NavigationService().go(context, savedRoute);
    } else if (mounted) {
      NavigationService().go(context, AppRoutes.dashboard);
    }
  }

  void _navigateToLogin() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _timeoutTimer?.cancel();

    NavigationService().go(context, AppRoutes.login);
  }

  void _retry() {
    setState(() {
      _hasNavigated = false;
      _statusMessage = LocaleKeys.initializing;
      _isLoading = true;
    });
    _initializeSplash();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) => _handleAuthState(state),
      child: Scaffold(
        body: ResponsiveBuilder(
          builder: (context, device) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.8),
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: device.value(
                          mobile: 24,
                          tablet: 48,
                          desktop: 64,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),
                          // Logo
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildLogo(device),
                          ),
                          SizedBox(
                            height: device.value(
                              mobile: 24,
                              tablet: 32,
                              desktop: 40,
                            ),
                          ),
                          // App Name
                          MyText(
                            LocaleKeys.appName,
                            fontSize: device.value(
                              mobile: 28,
                              tablet: 36,
                              desktop: 42,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          // Tagline
                          MyText(
                            LocaleKeys.appTagline,
                            fontSize: device.value(
                              mobile: 14,
                              tablet: 16,
                              desktop: 18,
                            ),
                            color: Colors.white70,
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),
                          // Status Section
                          _buildStatusSection(device),
                          const Spacer(),
                          // Version & Debug Info
                          _buildFooter(device),
                          SizedBox(
                            height: device.value(
                              mobile: 16,
                              tablet: 24,
                              desktop: 32,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildLogo(ResponsiveDevice device) {
    final size = device
        .value(mobile: 140, tablet: 160, desktop: 180)
        .toDouble();
    final iconSize = device
        .value(mobile: 40, tablet: 68, desktop: 80)
        .toDouble();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        //  borderRadius: BorderRadius.circular(size / 2),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AppLogo(size: iconSize),
    );
  }

  Widget _buildStatusSection(ResponsiveDevice device) {
    final isError = _statusMessage.startsWith('error');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Loading indicator or status icon
        SizedBox(
          height: 48,
          width: 48,
          child: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                )
              : Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  size: 48,
                  color: Colors.white,
                ),
        ),
        const SizedBox(height: 16),
        // Status message
        MyText(
          _statusMessage,
          fontSize: device.value(mobile: 14, tablet: 16, desktop: 16),
          color: Colors.white,
          textAlign: TextAlign.center,
        ),
        // Retry button on error
        if (isError) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const MyText(
              LocaleKeys.tapToRetry,
              color: Colors.white,
              fontSize: 14,
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(ResponsiveDevice device) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Version
        const MyText(
          'v1.0.0',
          fontSize: 12,
          color: Colors.white54,
          noTranslation: true,
        ),
        // Debug info
        if (Env.debugMode) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bug_report, size: 14, color: Colors.white60),
                const SizedBox(width: 8),
                MyText(
                  Env.environmentName,
                  fontSize: 11,
                  color: Colors.white60,
                  noTranslation: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
