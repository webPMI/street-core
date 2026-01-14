import './legal_page.dart'; // For LegalSection enum
import './widgets/base_legal_page.dart';
import 'package:flutter/material.dart';

/// Refund Policy Page
///
/// Standalone page for deep linking and SEO.
/// Route: /refund-policy
class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseLegalPage(section: LegalSection.refund);
  }
}
