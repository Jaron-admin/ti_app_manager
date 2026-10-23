import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design/components/ti_busy.dart';
import '../../design/components/ti_empty.dart';
import '../../design/components/ti_page.dart';
import '../../design/tokens.dart';
import '../../shared/models.dart';

class UpdatesPage extends ConsumerStatefulWidget {
  const UpdatesPage({super.key});

  @override
  ConsumerState<UpdatesPage> createState() => _UpdatesPageState();
}

class _UpdatesPageState extends ConsumerState<UpdatesPage> {
  // Everything starts selected, so only the boxes the user clears are stored.
  final Set<String> _skipped = {};
  final Set<String> _updated = {};
  final Map<String, String> _errors = {};

  bool _busy = false;
  bool _finished = false;
  int _done = 0;
  int _total = 0;
  String _current = '';
  String? _firstError;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(availableUpdatesProvider);
    final entries = state.value ?? const <UpdateEntry>[];
    final selected = _selected(entries);

    return TiPage(
      key: const Key('page-updates'),
      title: '可更新',
      subtitle: !state.hasValue
          ? '正在检查这台电脑上的更新'
          : entries.isEmpty
          ? '全部是最新的'
          : '${entries.length} 个软件可以更新',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(entries, selected),
          const SizedBox(height: TiSpace.gap),
          if (_statusLine != null) ...[
            Text(_statusLine!, key: const Key('updates-status')),
            const SizedBox(height: TiSpace.gap),
          ],
          Expanded(child: _body(state, selected)),
        ],
      ),
    );
  }

  List<UpdateEntry> _selected(List<UpdateEntry> entries) =>
      entries.where((entry) => !_skipped.contains(entry.id)).toList();

  String? get _statusLine {
    if (_busy) {
      return _current.isEmpty
          ? '正在更新 $_done/$_total'
          : '正在更新 ${_done + 1}/$_total · $_current';
    }
    if (!_finished) return null;
    final summary = _errors.isEmpty
        ? '完成 ${_updated.length}'
        : '完成 ${_updated.length} · 失败 ${_errors.length}';
    return _firstError == null ? summary : '$summary · $_firstError';
  }

  Widget _toolbar(List<UpdateEntry> entries, List<UpdateEntry> selected) {
    final theme = Theme.of(context);
    final editable = entries.isNotEmpty && !_busy;

    return Row(
      children: [
        Checkbox(
          key: const Key('updates-select-all'),
          tristate: true,
          value: !editable
              ? null
              : selected.length == entries.length
              ? true
              : selected.isEmpty
              ? false
              : null,
          onChanged: editable
              ? (value) => setState(() {
                  if (value == false) {
                    _skipped.addAll(entries.map((entry) => entry.id));
                  } else {
                    _skipped.clear();
                  }
                })
              : null,
        ),
        Text('全选', style: theme.textTheme.bodyMedium),
        const Spacer(),
        FilledButton(
          key: const Key('updates-run'),
          onPressed: editable && selected.isNotEmpty
              ? () => _confirm(selected)
              : null,
          child: Text('更新 ${selected.length} 个'),
        ),
        const SizedBox(width: TiSpace.gap),
        IconButton(
          key: const Key('updates-refresh'),
          onPressed: _busy
              ? null
              : () => setState(() {
                  _finished = false;
                  _updated.clear();
                  _errors.clear();
                  _firstError = null;
                  ref.invalidate(availableUpdatesProvider);
                }),
          icon: const Icon(Icons.refresh),
          tooltip: '重新检查',
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

  Widget _body(
    AsyncValue<List<UpdateEntry>> state,
    List<UpdateEntry> selected,
  ) {
    if (state.hasError) {
      return TiEmpty(
        icon: Icons.error_outline,
        title: '检查失败',
        message: state.error.toString(),
        action: FilledButton(
          key: const Key('updates-retry'),
          onPressed: () => ref.invalidate(availableUpdatesProvider),
          child: const Text('重新检查'),
        ),
      );
    }
    if (!state.hasValue) {
      return const TiBusy(title: '正在检查', message: 'winget 正在比对版本，约需 15 秒。');
    }
    final entries = state.requireValue;
    if (entries.isEmpty) {
      return const TiEmpty(
        icon: Icons.task_alt,
        title: '全部是最新的',
        message: 'winget 没有发现可升级的软件。',
      );
    }
    final chosen = {for (final entry in selected) entry.id};

    return ListView.separated(
      key: const Key('updates-list'),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _UpdateRow(
          entry: entry,
          checked: chosen.contains(entry.id),
          enabled: !_busy,
          status: _errors.containsKey(entry.id)
              ? '失败'
              : _updated.contains(entry.id)
              ? '完成'
              : (_busy && _current == entry.name)
              ? '更新中'
              : null,
          onToggle: (value) => setState(() {
            if (value) {
              _skipped.remove(entry.id);
            } else {
              _skipped.add(entry.id);
            }
          }),
        );
      },
    );
  }

  Future<void> _confirm(List<UpdateEntry> targets) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('更新 ${targets.length} 个软件？'),
        content: const Text('winget 会依次静默安装这些更新，期间可以继续用其他软件。'),
        actions: [
          TextButton(
            // Focus has to land inside the dialog or Escape stays outside it.
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('updates-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('开始更新'),
          ),
        ],
      ),
    );
    if (go == true) await _run(targets);
  }

  Future<void> _run(List<UpdateEntry> targets) async {
    final service = ref.read(wingetProvider);
    setState(() {
      _busy = true;
      _finished = false;
      _done = 0;
      _total = targets.length;
      _firstError = null;
      _updated.clear();
      _errors.clear();
    });

    for (final entry in targets) {
      setState(() => _current = entry.name);
      try {
        await service.update(entry);
        _updated.add(entry.id);
      } catch (error) {
        _errors[entry.id] = '$error';
        _firstError ??= '$error';
      }
      setState(() => _done++);
    }

    setState(() {
      _busy = false;
      _finished = true;
      _current = '';
    });
    // A newer version on disk makes the installed list stale; a run where
    // nothing succeeded does not.
    if (_updated.isNotEmpty) ref.invalidate(installedAppsProvider);
  }
}

class _UpdateRow extends StatelessWidget {
  const _UpdateRow({
    required this.entry,
    required this.checked,
    required this.enabled,
    required this.onToggle,
    this.status,
  });

  final UpdateEntry entry;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: TiSpace.listRowTwoLine),
      child: Align(
        alignment: Alignment.center,
        child: Row(
          children: [
            Checkbox(
              key: Key('check-${entry.id}'),
              value: checked,
              onChanged: enabled ? (value) => onToggle(value ?? false) : null,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: TiSpace.gap / 2),
                  Text(
                    '${entry.id} · ${entry.source}',
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
                Text(entry.currentVersion, style: theme.textTheme.bodyMedium),
                const SizedBox(height: TiSpace.gap / 2),
                Text(
                  '→ ${entry.availableVersion}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (status != null)
              SizedBox(
                width: TiSpace.block * 2,
                child: Padding(
                  padding: const EdgeInsets.only(left: TiSpace.gap),
                  child: Text(
                    status!,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
