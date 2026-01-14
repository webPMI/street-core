import '../../../core/lang/locale_keys.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: MyText(LocaleKeys.helpCenter, istitle: true)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            context,
            question: LocaleKeys.howToCreateCompetition,
            answer: LocaleKeys.howToCreateCompetitionDesc,
          ),
          _buildFAQItem(
            context,
            question: LocaleKeys.howToJoinClub,
            answer: LocaleKeys.howToJoinClubDesc,
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email),
               title: MyText(LocaleKeys.contactSupport, selectable: false),
               subtitle: const MyText(
                 'support@fitriders.com',
                 selectable: false,
                 noTranslation: true,
               ),
              onTap: () {
                // Launch email
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description),
               title: MyText(LocaleKeys.termsOfService, selectable: false),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.termsOfService),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.privacy_tip),
               title: MyText(LocaleKeys.privacyPolicy, selectable: false),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Card(
      child: ExpansionTile(
        title: MyText(question, istitle: true, selectable: false),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: MyText(answer),
          ),
        ],
      ),
    );
  }
}
