import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/my_text.dart';
import '../bloc/notification_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationSettingsCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: MyText(LocaleKeys.notifications, istitle: true),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(context, context.tr(LocaleKeys.pushNotifications)),
            BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
              builder: (context, state) {
                final cubit = context.read<NotificationSettingsCubit>();
                return Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: MyText(LocaleKeys.enablePush, selectable: false),
                        subtitle: MyText(LocaleKeys.receivePushDescription, selectable: false),
                        value: state.pushEnabled,
                        onChanged: cubit.togglePush,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, context.tr(LocaleKeys.emailNotifications)),
            BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
              builder: (context, state) {
                final cubit = context.read<NotificationSettingsCubit>();
                return Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: MyText(LocaleKeys.enableEmail, selectable: false),
                        subtitle: MyText(LocaleKeys.receiveEmailDescription, selectable: false),
                        value: state.emailEnabled,
                        onChanged: cubit.toggleEmail,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: MyText(LocaleKeys.marketingEmails, selectable: false),
                        subtitle: MyText(LocaleKeys.receiveMarketingDescription, selectable: false),
                        value: state.marketingEnabled,
                        onChanged: cubit.toggleMarketing,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: MyText(
        title,
        istitle: true,
     
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
