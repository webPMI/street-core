import 'package:flutter/material.dart';
import 'package:street_core/core/helpers/logger.dart';

import 'my_text.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    super.key,
    this.message,
    this.title,
    this.subtitle,
    this.onRetry,
  });
  final String? message;
  final String? title;
  final String? subtitle;

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('ERROR CARD LOADED $message');
    return Scaffold(
      appBar: AppBar(title: MyText('error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (title != null) MyText(title!),
            if (subtitle != null) MyText(subtitle!),
            Icon(
              Icons.error_outline,
              size: 60,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            if (message != null)
              MyText(message!, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            if (onRetry != null)
              ElevatedButton(onPressed: onRetry, child: MyText('retry')),
          ],
        ),
      ),
    );
  }
}
