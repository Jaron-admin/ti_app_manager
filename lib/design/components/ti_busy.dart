import 'package:flutter/material.dart';

import '../tokens.dart';

/// Waiting state for work that really takes seconds, such as a winget call.
class TiBusy extends StatelessWidget {
  const TiBusy({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: TiSpace.block,
            height: TiSpace.block,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: TiSpace.card),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: TiSpace.gap),
          Text(message, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
