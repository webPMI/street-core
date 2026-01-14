import './legal_page.dart'; // For LegalSection enum
import './widgets/base_legal_page.dart';
import 'package:flutter/material.dart';

/// Privacy Policy Page
///
/// Standalone page for deep linking and SEO.
/// Route: /privacy-policy
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseLegalPage(section: LegalSection.privacy);
  }
}
