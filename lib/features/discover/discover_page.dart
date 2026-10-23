import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design/components/ti_busy.dart';
import '../../design/components/ti_empty.dart';
import '../../design/components/ti_page.dart';
import '../../design/tokens.dart';
import '../../shared/models.dart';
import '../../shared/winget_service.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final _query = TextEditingController();
  String _submitted = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(TiRadius.all),
      borderSide: BorderSide(color: theme.dividerColor),
    );

    return TiPage(
      key: const Key('page-discover'),
      title: '发现',
      subtitle: _submitted.isEmpty
          ? '从 winget 里找软件安装'
          : 'winget 里与“$_submitted”相关的软件',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: TiSpace.tapTarget,
            child: TextField(
              key: const Key('discover-search'),
              controller: _query,
              style: theme.textTheme.bodyMedium,
              onSubmitted: (value) => setState(() => _submitted = value.trim()),
              decoration: InputDecoration(
                hintText: '输入软件名，回车搜索',
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
          const SizedBox(height: TiSpace.gap),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_submitted.isEmpty) {
      return const TiEmpty(
        icon: Icons.explore_outlined,
        title: '还没搜索',
        message: '输入软件名，回车从 winget 里找安装包。',
      );
    }

    final state = ref.watch(discoverSearchProvider(_submitted));
    if (state.hasValue) {
      final results = state.requireValue;
      if (results.isEmpty) {
        return TiEmpty(
          icon: Icons.search_off,
          title: '没有匹配的软件',
          message: '“$_submitted” 没有搜索结果。',
        );
      }
      return _results(results);
    }
    if (state.hasError) {
      return TiEmpty(
        icon: Icons.error_outline,
        title: '搜索失败',
        message: state.error.toString(),
        action: FilledButton(
          onPressed: () => ref.invalidate(discoverSearchProvider(_submitted)),
          child: const Text('重新搜索'),
        ),
      );
    }
    return const TiBusy(title: '正在搜索', message: 'winget 正在查询软件源。');
  }

  Widget _results(List<SearchResult> results) {
    final apps =
        ref.watch(installedAppsProvider).value ?? const <InstalledApp>[];
    final installed = {for (final app in apps) app.id.toLowerCase()};

    return ListView.separated(
      key: const Key('discover-list'),
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final result = results[index];
        return _ResultRow(
          result: result,
          alreadyInstalled: installed.contains(result.id.toLowerCase()),
          onInstall: () => _install(result),
        );
      },
    );
  }

  Future<void> _install(SearchResult result) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('安装 ${result.name}？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in [
              result.id,
              '${result.version} · ${result.source}',
              if (result.match.isNotEmpty) '匹配 ${result.match}',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: TiSpace.gap / 2),
                child: Text(line, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
        actions: [
          TextButton(
            // Focus has to land inside the dialog or Escape stays with the search field.
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('install-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('安装'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final installed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _InstallDialog(result: result, service: ref.read(wingetProvider)),
    );
    if (installed == true) ref.invalidate(installedAppsProvider);
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.result,
    required this.alreadyInstalled,
    required this.onInstall,
  });

  final SearchResult result;
  final bool alreadyInstalled;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      result.id,
      result.version,
      // The same name can come from winget or from the store.
      if (result.source.isNotEmpty) result.source,
    ].join(' · ');

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
                    result.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: TiSpace.gap / 2),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: TiSpace.gap),
            if (alreadyInstalled)
              Text('已安装', style: theme.textTheme.labelSmall)
            else
              FilledButton(
                key: Key('install-${result.id}'),
                onPressed: onInstall,
                child: const Text('安装'),
              ),
          ],
        ),
      ),
    );
  }
}

class _InstallDialog extends StatefulWidget {
  const _InstallDialog({required this.result, required this.service});

  final SearchResult result;
  final WingetService service;

  @override
  State<_InstallDialog> createState() => _InstallDialogState();
}

class _InstallDialogState extends State<_InstallDialog> {
  Object? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      await widget.service.install(widget.result);
      if (mounted) setState(() => _done = true);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finished = _done || _error != null;

    return AlertDialog(
      title: Text(
        _error != null
            ? '安装失败'
            : (_done ? '装好了' : '正在安装 ${widget.result.name}'),
      ),
      content: Row(
        children: [
          if (!finished)
            const SizedBox(
              width: TiSpace.card,
              height: TiSpace.card,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: TiSpace.card),
          Expanded(
            child: Text(
              _error?.toString() ??
                  '${widget.result.id} · ${widget.result.version}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
      actions: [
        if (finished)
          FilledButton(
            key: const Key('install-close'),
            onPressed: () => Navigator.pop(context, _done),
            child: Text(_done ? '完成' : '关闭'),
          ),
      ],
    );
  }
}
