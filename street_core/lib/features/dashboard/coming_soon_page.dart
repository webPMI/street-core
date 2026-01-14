import '../../../core/lang/context_tr.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/widgets/drawer/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A placeholder page for features that are planned but not yet implemented.
///
/// Displays a friendly "Coming Soon" message with the feature name
/// and provides navigation back to the dashboard.
class ComingSoonPage extends StatelessWidget {
  final String featureName;
  final String? featureKey; // Optional translation key for feature name

  const ComingSoonPage({super.key, required this.featureName, this.featureKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = featureKey != null ? featureKey! : featureName;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.hourglass_empty),
            const SizedBox(width: 8),
            MyText(displayName),
          ],
        ),
      ),
      drawer: MyDrawer(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Construction icon with theme color
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction_rounded,
                  size: 64,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 32),

              // Feature name
              Text(
                featureKey != null ? context.tr(featureKey!) : featureName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Coming soon message
              MyText(
                'coming_soon',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Additional info
              MyText(
                'feature_in_development',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Back to dashboard button
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.arrow_back),
                label: MyText(
                  'back_to_dashboard',
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
