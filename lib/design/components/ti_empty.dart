import 'package:flutter/material.dart';

import '../tokens.dart';

class TiEmpty extends StatelessWidget {
  const TiEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: TiSpace.listRow,
              height: TiSpace.listRow,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: TiSpace.block,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: TiSpace.card),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: TiSpace.gap),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (action != null) ...[
              const SizedBox(height: TiSpace.card),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
