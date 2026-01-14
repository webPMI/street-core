import 'package:flutter/material.dart';
import 'package:street_core/core/lang/locale_keys.dart';

import '../../core/widgets/my_text.dart';

/// Sheet que muestra cuando el usuario no está autenticado
class FastLogingAndRegister extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const FastLogingAndRegister({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icono
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Título
          MyText(
            LocaleKeys.loginRequired,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Descripción
          MyText(
            LocaleKeys.loginToRegisterCompetition,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRegister,
                  child: const MyText(LocaleKeys.createAccount),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:
                    FilledButton(onPressed: onLogin, child: const MyText(LocaleKeys.logIn)),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
