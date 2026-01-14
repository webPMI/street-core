import '../../../core/widgets/my_card.dart';
import '../../../core/widgets/my_text.dart';
import 'package:flutter/material.dart';

//---Tarjeta genérica para mostrar servicios o características con hover
class FeatureCard extends StatelessWidget {

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MyResponsiveCard(
      onTap: onTap,
      hoverEffect: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          _buildIcon(theme),
          const SizedBox(height: 20),

          // Texts
          MyText(
            title,
            istitle: true,

            selectable: false,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          MyText(
            description,
            selectable: false,
            color: theme.colorScheme.onSurfaceVariant,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Action Arrow (Static style for simplicity, or we can make it dynamic if needed)
          Icon(Icons.arrow_forward, size: 20, color: theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 48, color: theme.colorScheme.primary),
    );
  }
}
