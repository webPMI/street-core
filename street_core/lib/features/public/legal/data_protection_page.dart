import './legal_page.dart'; // For LegalSection enum
import './widgets/base_legal_page.dart';
import 'package:flutter/material.dart';

/// Data Protection Page
///
/// Standalone page for deep linking and SEO.
/// Route: /data-protection
class DataProtectionPage extends StatelessWidget {
  const DataProtectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseLegalPage(section: LegalSection.dataProtection);
  }
}
