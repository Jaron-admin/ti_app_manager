import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design/components/ti_empty.dart';
import '../../design/components/ti_page.dart';
import '../../design/tokens.dart';
import '../../shared/models.dart';

class InstalledPage extends ConsumerStatefulWidget {
  const InstalledPage({super.key});

  @override
  ConsumerState<InstalledPage> createState() => _InstalledPageState();
}

class _InstalledPageState extends ConsumerState<InstalledPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(installedAppsProvider);
    final apps = state.value ?? const <InstalledApp>[];

    return TiPage(
      key: const Key('page-installed'),
      title: '已安装',
      subtitle: state.hasValue ? '这台电脑上的 ${apps.length} 个软件' : '这台电脑上的软件',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toolbar(
            query: _query,
            onChanged: (_) => setState(() {}),
            onRefresh: () => ref.invalidate(installedAppsProvider),
            canRefresh: !state.isLoading,
          ),
          const SizedBox(height: TiSpace.gap),
          Expanded(child: _status(state)),
        ],
      ),
    );
  }

  Widget _status(AsyncValue<List<InstalledApp>> state) {
    // Stale rows stay on screen while a refresh runs; winget only answers with
    // an error when there is nothing to keep showing.
    if (state.hasValue) return _list(state.requireValue);
    if (state.hasError) {
      return TiEmpty(
        icon: Icons.error_outline,
        title: '读取失败',
        message: state.error.toString(),
        action: FilledButton(
          key: const Key('installed-retry'),
          onPressed: () => ref.invalidate(installedAppsProvider),
          child: const Text('重新读取'),
        ),
      );
    }
    return const _Busy(
      title: '正在读取',
      message: 'winget 正在列出这台电脑上的软件，首次约需 20 秒。',
    );
  }

  Widget _list(List<InstalledApp> apps) {
    final query = _query.text.trim().toLowerCase();
    if (apps.isEmpty) {
      return const TiEmpty(
        icon: Icons.inventory_2_outlined,
        title: '没有软件',
        message: 'winget 没有返回任何条目。',
      );
    }
    final visible = query.isEmpty
        ? apps
        : apps
              .where(
                (app) =>
                    app.name.toLowerCase().contains(query) ||
                    app.id.toLowerCase().contains(query),
              )
              .toList();
    if (visible.isEmpty) {
      return TiEmpty(
        icon: Icons.search_off,
        title: '没有匹配的软件',
        message: '换个关键词试试。',
      );
    }

    return ListView.separated(
      key: const Key('installed-list'),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const _RowDivider(),
      itemBuilder: (context, index) => _AppRow(app: visible[index]),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.query,
    required this.onChanged,
    required this.onRefresh,
    required this.canRefresh,
  });

  final TextEditingController query;
  final ValueChanged<String> onChanged;
  final VoidCallback onRefresh;
  final bool canRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(TiRadius.all),
      borderSide: BorderSide(color: theme.dividerColor),
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: TiSpace.tapTarget,
            child: TextField(
              key: const Key('installed-search'),
              controller: query,
              onChanged: onChanged,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: '搜索软件名或 ID',
                hintStyle: theme.textTheme.bodySmall,
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: TiType.headline),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: TiSpace.gap),
        IconButton(
          key: const Key('installed-refresh'),
          onPressed: canRefresh ? onRefresh : null,
          icon: const Icon(Icons.refresh),
          tooltip: '重新读取',
          style: IconButton.styleFrom(
            minimumSize: Size(TiSpace.tapTarget, TiSpace.tapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TiRadius.all),
              side: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({required this.app});

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final update = app.availableVersion;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: TiSpace.listRowTwoLine),
      child: Align(
        alignment: Alignment.center,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: TiSpace.gap / 2),
                  Text(
                    app.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: TiSpace.gap),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(app.version, style: theme.textTheme.bodyMedium),
                const SizedBox(height: TiSpace.gap / 2),
                if (app.updateAvailable)
                  Text(
                    '可更新 $update',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  )
                else
                  Text(
                    app.source.isEmpty ? '本机' : app.source,
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Theme.of(context).dividerColor);
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.title, required this.message});

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
