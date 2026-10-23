import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../features/about/about_page.dart';
import '../features/discover/discover_page.dart';
import '../features/installed/installed_page.dart';
import '../features/updates/updates_page.dart';
import 'app_info.dart';

/// Desktop shell: fixed sidebar plus a state-preserving page stack.
class TiShell extends StatefulWidget {
  const TiShell({super.key});

  @override
  State<TiShell> createState() => _TiShellState();
}

enum TiSection { installed, updates, discover, about }

class _TiShellState extends State<TiShell> {
  TiSection _section = TiSection.installed;

  static const _pages = <Widget>[
    InstalledPage(),
    UpdatesPage(),
    DiscoverPage(),
    AboutPage(),
  ];

  static const _destinations = <_Destination>[
    _Destination(
      section: TiSection.installed,
      label: '已安装',
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
    ),
    _Destination(
      section: TiSection.updates,
      label: '可更新',
      icon: Icons.arrow_circle_up_outlined,
      activeIcon: Icons.arrow_circle_up,
    ),
    _Destination(
      section: TiSection.discover,
      label: '发现',
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
    ),
    _Destination(
      section: TiSection.about,
      label: '关于',
      icon: Icons.info_outline,
      activeIcon: Icons.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context),
          Expanded(
            child: Stack(
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Positioned.fill(
                    child: Offstage(
                      offstage: i != _section.index,
                      child: TickerMode(
                        enabled: i == _section.index,
                        child: _pages[i],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TiSpace.page,
          TiSpace.block,
          TiSpace.page,
          TiSpace.page,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrand(context),
            const SizedBox(height: TiSpace.block + TiSpace.gap),
            Text('管理', style: theme.textTheme.labelSmall),
            const SizedBox(height: TiSpace.gap),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final destination in _destinations)
                    _buildNavItem(context, destination),
                ],
              ),
            ),
            Divider(color: theme.dividerColor),
            const SizedBox(height: TiSpace.card),
            Text('引擎', style: theme.textTheme.labelSmall),
            const SizedBox(height: TiSpace.gap / 2),
            Text('winget · BCUninstaller', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildBrand(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: TiSpace.tapTarget,
          height: TiSpace.tapTarget,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(TiRadius.all),
          ),
          child: Text(
            'Ti',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppInfo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Text('Windows', style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, _Destination destination) {
    final theme = Theme.of(context);
    final selected = _section == destination.section;
    final primary = theme.colorScheme.primary;
    final muted = TiColors.muted;

    return Padding(
      padding: const EdgeInsets.only(bottom: TiSpace.gap / 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(TiRadius.all),
          child: InkWell(
            key: _navKey(destination.section),
            borderRadius: BorderRadius.circular(TiRadius.all),
            onTap: () => setState(() => _section = destination.section),
            hoverColor: primary.withValues(alpha: 0.06),
            child: SizedBox(
              height: TiSpace.tapTarget,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      selected ? destination.activeIcon : destination.icon,
                      size: TiSpace.page,
                      color: selected ? primary : muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: selected ? theme.colorScheme.onSurface : muted,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Key _navKey(TiSection section) => switch (section) {
    TiSection.installed => const Key('nav-installed'),
    TiSection.updates => const Key('nav-updates'),
    TiSection.discover => const Key('nav-discover'),
    TiSection.about => const Key('nav-about'),
  };
}

class _Destination {
  const _Destination({
    required this.section,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final TiSection section;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
