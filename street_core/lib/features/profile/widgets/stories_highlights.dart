import 'package:flutter/material.dart';

import '../../../core/widgets/my_text.dart';

/// Stories Highlights Section
/// Displays horizontal scrolling list of story highlights
class StoriesHighlights extends StatelessWidget {
  const StoriesHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Placeholder stories data - would come from backend
    final stories = <Map<String, dynamic>>[
      {'title': 'highlights', 'icon': Icons.add, 'isAdd': true},
    ];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          final isAdd = story['isAdd'] == true;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isAdd
                            ? theme.colorScheme.outline
                            : theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        story['icon'] as IconData,
                        size: 18,
                        color: isAdd
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  MyText(
                    story['title'] as String,
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
