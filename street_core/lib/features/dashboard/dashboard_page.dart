import '../../../core/widgets/my_text.dart';
import '../../../core/widgets/drawer/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:street_core/core/lang/locale_keys.dart';

import '../auth/bloc/user_cubit.dart';
import '../auth/bloc/user_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return LocaleKeys.goodMorning;
    if (hour < 18) return LocaleKeys.goodAfternoon;
    return LocaleKeys.goodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.dashboard),
            const SizedBox(width: 8),
            const MyText(LocaleKeys.appTitle,),
          ],
        ),
      ),
      drawer: MyDrawer(),
      body: BlocBuilder<UserCubit, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserLoaded) {
            final greeting = _getGreeting();
            final userName = state.user.firstName.isNotEmpty
                ? state.user.firstName
                : state.user.nickName ?? '';

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MyText(
                              '$greeting, $userName',
                              istitle: true,
                              fontSize: 24,
                              noTranslation: true,
                          
                            ),
                            const SizedBox(height: 4),
                            MyText(
                              'dashboard.subtitle',
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // Error state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                MyText(LocaleKeys.errorLoadingUser),
              ],
            ),
          );
        },
      ),
    );
  }
}
