import './legal_page.dart'; // For LegalSection enum
import './widgets/base_legal_page.dart';
import 'package:flutter/material.dart';

/// Terms of Service Page
///
/// Standalone page for deep linking and SEO.
/// Route: /terms-of-service
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseLegalPage(section: LegalSection.terms);
  }
}
