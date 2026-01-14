import 'package:flutter/material.dart';

class DefaultBanner extends StatelessWidget {
  const DefaultBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withAlpha(179),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.emoji_events,
          size: 64,
          color: Colors.white.withAlpha(179),
        ),
      ),
    );
  }
}
