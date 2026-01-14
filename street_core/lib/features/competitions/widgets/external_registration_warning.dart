import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';
import '../../../core/widgets/my_text.dart';
import '../models/competition.dart';

/// Widget to display a prominent warning when competition uses external registration.
/// Warns users that they will leave the StreetCore platform and shows exit confirmation.
class ExternalRegistrationWarning extends StatelessWidget {
  final Competition competition;

  const ExternalRegistrationWarning({
    super.key,
    required this.competition,
  });

  /// Launch external registration URL in browser
  Future<void> _launchExternalRegistration(BuildContext context) async {
    final url = competition.externalRegistrationUrl;

    if (url == null || url.isEmpty) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          'External registration URL not available',
        );
      }
      return;
    }

    // Try to parse the URL
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        SnackBarHelper.showError(
          context,
          'Invalid registration URL',
        );
      }
      return;
    }

    // Show confirmation dialog before leaving the app
    if (context.mounted) {
      _showExitConfirmation(context, uri);
    }
  }

  /// Show confirmation dialog before opening external URL
  void _showExitConfirmation(BuildContext context, Uri url) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: MyText(
          context.tr(LocaleKeys.warning),
          selectable: false,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: MyText(
          'You will leave StreetCore and go to ${competition.externalProvider ?? "the registration site"}. Continue?',
          selectable: false,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: MyText(
              context.tr(LocaleKeys.cancel),
              selectable: false,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _openUrl(url);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.warning,
              foregroundColor: Colors.white,
            ),
            child: MyText(
              'Continue to ${competition.externalProvider ?? "Registration"}',
              selectable: false,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Open URL in browser
  Future<void> _openUrl(Uri url) async {
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // Error will be handled by the SnackbarHelper at higher level
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!competition.isExternalRegistration) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.warningContainer,
        border: Border.all(
          color: colorScheme.warning,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Warning header
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: colorScheme.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MyText(
                  'External Registration',
                  selectable: false,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onWarningContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Warning message
          MyText(
            'This competition uses a third-party registration site. You will leave StreetCore to complete your registration.',
            selectable: false,
            style: TextStyle(
              color: colorScheme.onWarningContainer,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Provider info (if available)
          if (competition.externalProvider != null &&
              competition.externalProvider!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MyText(
                      'Platform: ${competition.externalProvider}',
                      selectable: false,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (competition.externalProvider != null &&
              competition.externalProvider!.isNotEmpty)
            const SizedBox(height: 16),

          // Register button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchExternalRegistration(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.open_in_new),
              label: MyText(
                'Continue to ${competition.externalProvider ?? "Registration"}',
                selectable: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension for convenient warning color access
extension WarningColorScheme on ColorScheme {
  Color get warning => Color(0xFFF57C00); // Orange warning color
  Color get warningContainer => Color(0xFFFFE0B2); // Light orange container
  Color get onWarningContainer => Color(0xFF331B00); // Dark text for container
}
