import './legal_page.dart'; // For LegalSection enum
import './widgets/base_legal_page.dart';
import 'package:flutter/material.dart';

/// Cookie Policy Page
///
/// Standalone page for deep linking and SEO.
/// Route: /cookie-policy
class CookiePolicyPage extends StatelessWidget {
  const CookiePolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseLegalPage(section: LegalSection.cookies);
  }
}
