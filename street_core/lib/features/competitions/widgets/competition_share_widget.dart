import '../models/competition.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/lang/context_tr.dart';
import '../../../core/lang/locale_keys.dart';

/// Widget for sharing competitions on social media
///
/// Provides share buttons for:
/// - Native share dialog (mobile)
/// - Twitter
/// - Facebook
/// - LinkedIn
/// - WhatsApp
/// - Copy link
class CompetitionShareWidget extends StatelessWidget {
  const CompetitionShareWidget({
    super.key,
    required this.competition,
    //todo
    this.baseUrl = '',
  });
  final Competition competition;
  final String? baseUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr(LocaleKeys.shareThisCompetition),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _ShareButton(
              icon: Icons.share,
              label: context.tr(LocaleKeys.shareButton),
              color: Colors.blue,
              onPressed: () => _shareNative(context),
            ),
            _ShareButton(
              icon: Icons.link,
              label: context.tr(LocaleKeys.copyLink),
              color: Colors.grey,
              onPressed: () => _copyLink(context),
            ),
            _SocialShareButton(
              platform: SocialPlatform.twitter,
              onPressed: () => _shareOnTwitter(context),
            ),
            _SocialShareButton(
              platform: SocialPlatform.facebook,
              onPressed: () => _shareOnFacebook(),
            ),
            _SocialShareButton(
              platform: SocialPlatform.linkedin,
              onPressed: () => _shareOnLinkedIn(),
            ),
            _SocialShareButton(
              platform: SocialPlatform.whatsapp,
              onPressed: () => _shareOnWhatsApp(context),
            ),
          ],
        ),
      ],
    );
  }

  String get _shareUrl {
    final slug = _generateSlug(competition.title);
    return '$baseUrl/competitions/${competition.id}/$slug';
  }

  String _shareText(BuildContext context) {
    return '${competition.title} - ${competition.discipline ?? context.tr(LocaleKeys.competition)} '
        'on ${_formatDate(competition.startDate)}. '
        '${context.tr(LocaleKeys.joinOnFitRidersPro)}!';
  }

  Future<void> _shareNative(BuildContext context) async {
    try {
      // ignore: deprecated_member_use
      await Share.share(
        '$_shareText\n\n$_shareUrl',
        subject: competition.title,
      );
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, LocaleKeys.failedToShare);
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    try {
      // ignore: deprecated_member_use
      await Share.share(_shareUrl);
      if (context.mounted) {
        SnackBarHelper.showSuccess(context, LocaleKeys.linkCopied);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, LocaleKeys.failedToCopyLink);
      }
    }
  }

  Future<void> _shareOnTwitter(BuildContext context) async {
    final text = Uri.encodeComponent(_shareText(context));
    final url = Uri.encodeComponent(_shareUrl);
    final twitterUrl = Uri.parse(
      'https://twitter.com/intent/tweet?text=$text&url=$url&via=fitriders',
    );
    await _launchUrl(twitterUrl);
  }

  Future<void> _shareOnFacebook() async {
    final url = Uri.encodeComponent(_shareUrl);
    final facebookUrl = Uri.parse(
      'https://www.facebook.com/sharer/sharer.php?u=$url',
    );
    await _launchUrl(facebookUrl);
  }

  Future<void> _shareOnLinkedIn() async {
    final url = Uri.encodeComponent(_shareUrl);
    final linkedInUrl = Uri.parse(
      'https://www.linkedin.com/sharing/share-offsite/?url=$url',
    );
    await _launchUrl(linkedInUrl);
  }

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final text = Uri.encodeComponent('${_shareText(context)} $_shareUrl');
    final whatsappUrl = Uri.parse('https://wa.me/?text=$text');
    await _launchUrl(whatsappUrl);
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Share button widget
class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Social media platform enum
enum SocialPlatform { twitter, facebook, linkedin, whatsapp }

/// Social media specific share button
class _SocialShareButton extends StatelessWidget {
  const _SocialShareButton({required this.platform, required this.onPressed});
  final SocialPlatform platform;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final config = _getPlatformConfig(platform);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: config.color, shape: BoxShape.circle),
        child: Icon(config.icon, color: Colors.white, size: 24),
      ),
    );
  }

  _PlatformConfig _getPlatformConfig(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.twitter:
        return _PlatformConfig(
          icon: Icons.tag, // Use appropriate icon or custom icon
          color: const Color(0xFF1DA1F2),
        );
      case SocialPlatform.facebook:
        return _PlatformConfig(
          icon: Icons.facebook,
          color: const Color(0xFF4267B2),
        );
      case SocialPlatform.linkedin:
        return _PlatformConfig(
          icon: Icons.business, // Use appropriate icon
          color: const Color(0xFF0077B5),
        );
      case SocialPlatform.whatsapp:
        return _PlatformConfig(
          icon: Icons.chat, // Use appropriate icon
          color: const Color(0xFF25D366),
        );
    }
  }
}

class _PlatformConfig {
  _PlatformConfig({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

/// Compact share button for toolbar/appbar
class CompactShareButton extends StatelessWidget {
  const CompactShareButton({
    super.key,
    required this.competition,
    this.baseUrl,
  });
  final Competition competition;
  final String? baseUrl;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: () => _showShareSheet(context),
      tooltip: context.tr(LocaleKeys.shareCompetitionTooltip),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: CompetitionShareWidget(
          competition: competition,
          baseUrl: baseUrl,
        ),
      ),
    );
  }
}
