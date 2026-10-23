import 'package:flutter/material.dart';

import '../tokens.dart';

class TiCard extends StatelessWidget {
  const TiCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TiSpace.card),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(TiRadius.all),
        border: Border.all(color: theme.dividerColor),
        boxShadow: TiShadows.card,
      ),
      child: child,
    );
  }
}
