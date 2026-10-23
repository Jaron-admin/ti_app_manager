import 'package:flutter/material.dart';

import '../tokens.dart';

class TiPage extends StatelessWidget {
  const TiPage({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TiSpace.page,
        TiSpace.block,
        TiSpace.page,
        TiSpace.page,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.headlineSmall),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: TiSpace.gap / 2),
            Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: TiSpace.block),
          Expanded(child: child),
        ],
      ),
    );
  }
}
