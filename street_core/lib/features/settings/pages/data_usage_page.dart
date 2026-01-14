import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/my_text.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../bloc/data_usage_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DataUsagePage extends StatelessWidget {
  const DataUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DataUsageCubit(),
      child: Scaffold(
        appBar: AppBar(title: MyText(LocaleKeys.dataUsage, istitle: true)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader(context, context.tr(LocaleKeys.mediaAutoDownload)),
            BlocBuilder<DataUsageCubit, DataUsageState>(
              builder: (context, state) {
                final cubit = context.read<DataUsageCubit>();
                return Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: MyText(LocaleKeys.autoplayVideos, selectable: false),
                        subtitle: MyText(
                          _getAutoplayText(context, state.autoplayVideos),
                          selectable: false,
                        ),
                        trailing: PopupMenuButton<AutoplayOption>(
                          onSelected: cubit.setAutoplay,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: AutoplayOption.always,
                              child: MyText(LocaleKeys.always, selectable: false),
                            ),
                            PopupMenuItem(
                              value: AutoplayOption.wifiOnly,
                              child: MyText(LocaleKeys.wifiOnly, selectable: false),
                            ),
                            PopupMenuItem(
                              value: AutoplayOption.never,
                              child: MyText(LocaleKeys.never, selectable: false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: MyText(LocaleKeys.downloadWifiOnly, selectable: false),
                        value: state.downloadOverWifiOnly,
                        onChanged: cubit.toggleWifiDownload,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, context.tr(LocaleKeys.storage)),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_outline),
                title: MyText(LocaleKeys.clearCache, selectable: false),
                subtitle: MyText(LocaleKeys.freeUpSpace, selectable: false),
                onTap: () async {
                  // Show dialog or snackbar
                  SnackBarHelper.showSuccess(context, LocaleKeys.cacheCleared);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAutoplayText(BuildContext context, AutoplayOption option) {
    switch (option) {
      case AutoplayOption.always:
        return context.tr(LocaleKeys.always);
      case AutoplayOption.wifiOnly:
        return context.tr(LocaleKeys.wifiOnly);
      case AutoplayOption.never:
        return context.tr(LocaleKeys.never);
    }
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
