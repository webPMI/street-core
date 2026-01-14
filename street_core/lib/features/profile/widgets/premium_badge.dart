import 'package:flutter/material.dart';

import '../../../core/widgets/my_text.dart';

/// Premium Badge Widget
/// Displays a premium/pro badge with customizable size and style
class PremiumBadge extends StatelessWidget {

  const PremiumBadge({
    super.key,
    this.variant = BadgeVariant.large,
  });
  final BadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case BadgeVariant.large:
        return _buildLargeBadge();
      case BadgeVariant.small:
        return _buildSmallBadge();
    }
  }

  /// Large badge variant (used in header next to username)
  Widget _buildLargeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade700,
            Colors.amber.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          MyText(
            'premium.badge',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Small badge variant (used inline with name)
  Widget _buildSmallBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade600,
            Colors.orange.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: MyText(
        'pro.badge',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

enum BadgeVariant {
  large, // PREMIUM badge with star icon
  small, // PRO badge without icon
}
