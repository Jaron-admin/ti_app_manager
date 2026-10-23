import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design/tokens.dart';
import '../../shared/bcu_locator.dart';
import '../../shared/models.dart';
import '../../shared/registry_service.dart';

enum UninstallEngine { winget, native, bcu }

/// One button per row, and the menu only lists engines that exist for that
/// app: winget needs the source it recorded, the native path needs an ARP key,
/// the deep clean needs the user's own copy of BCUninstaller.
class UninstallAction extends ConsumerStatefulWidget {
  const UninstallAction({super.key, required this.app});

  final InstalledApp app;

  @override
  ConsumerState<UninstallAction> createState() => _UninstallActionState();
}

class _UninstallActionState extends ConsumerState<UninstallAction> {
  static const _labels = {
    UninstallEngine.winget: 'winget 卸载',
    UninstallEngine.native: '程序自带卸载器',
    UninstallEngine.bcu: 'BCU 深度清理',
  };
  static const _unavailable = {
    UninstallEngine.winget: '未跟踪',
    UninstallEngine.native: '无注册表项',
    UninstallEngine.bcu: '未安装',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = {
      UninstallEngine.winget: widget.app.source.isNotEmpty,
      UninstallEngine.native: arpKeyPath(widget.app.id) != null,
      UninstallEngine.bcu: ref.watch(bcuInstallProvider) != null,
    };

    return PopupMenuButton<UninstallEngine>(
      key: Key('uninstall-${widget.app.id}'),
      tooltip: '卸载 ${widget.app.name}',
      itemBuilder: (context) => [
        for (final engine in UninstallEngine.values)
          PopupMenuItem(
            value: engine,
            enabled: available[engine]!,
            child: SizedBox(
              width: 220,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _labels[engine]!,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: TiSpace.gap),
                  if (available[engine] != true)
                    Text(
                      _unavailable[engine]!,
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ),
      ],
      onSelected: _open,
      child: Container(
        height: TiSpace.tapTarget - 8,
        padding: const EdgeInsets.symmetric(horizontal: TiSpace.gap),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TiRadius.all),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('卸载', style: theme.textTheme.bodyMedium),
            const Icon(Icons.arrow_drop_down, size: TiType.title),
          ],
        ),
      ),
    );
  }

  Future<void> _open(UninstallEngine engine) async {
    final removed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UninstallDialog(
        app: widget.app,
        engine: engine,
        bcu: ref.read(bcuInstallProvider),
      ),
    );
    if (removed == true) ref.invalidate(installedAppsProvider);
  }
}

enum _Stage { preparing, confirming, running, done, failed }

/// Shows what is about to run, then runs it inside the same dialog: an
/// uninstall is the one action in this app that cannot be undone.
class _UninstallDialog extends ConsumerStatefulWidget {
  const _UninstallDialog({
    required this.app,
    required this.engine,
    required this.bcu,
  });

  final InstalledApp app;
  final UninstallEngine engine;
  final BcuInstall? bcu;

  @override
  ConsumerState<_UninstallDialog> createState() => _UninstallDialogState();
}

class _UninstallDialogState extends ConsumerState<_UninstallDialog> {
  late _Stage _stage = widget.engine == UninstallEngine.native
      ? _Stage.preparing
      : _Stage.confirming;
  RegistryUninstall? _entry;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (_stage == _Stage.preparing) _lookup();
  }

  Future<void> _lookup() async {
    try {
      final entry = await ref.read(uninstallerProvider(widget.app.id).future);
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _stage = _Stage.confirming;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _stage = _Stage.failed;
      });
    }
  }

  Future<void> _run() async {
    setState(() => _stage = _Stage.running);
    try {
      if (widget.engine == UninstallEngine.winget) {
        await ref.read(wingetProvider).uninstall(widget.app);
      } else {
        await ref.read(registryProvider).run(_entry!);
      }
      if (!mounted) return;
      setState(() => _stage = _Stage.done);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _stage = _Stage.failed;
      });
    }
  }

  void _openBcu() {
    // The window belongs to BCUninstaller, so waiting for it to exit would
    // leave this dialog spinning long after the user moved on.
    unawaited(ref.read(processRunnerProvider).run([widget.bcu!.guiExe]));
    Navigator.pop(context, false);
  }

  bool get _finished => _stage == _Stage.done || _stage == _Stage.failed;

  bool get _canRun => switch (widget.engine) {
    UninstallEngine.native => _entry != null,
    UninstallEngine.bcu => widget.bcu != null,
    UninstallEngine.winget => true,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_stage == _Stage.preparing || _stage == _Stage.running) ...[
            const SizedBox(
              width: TiSpace.card,
              height: TiSpace.card,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: TiSpace.gap),
          ],
          for (final line in _lines)
            Padding(
              padding: const EdgeInsets.only(bottom: TiSpace.gap / 2),
              child: Text(line, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
      actions: [
        if (!_finished)
          TextButton(
            // Focus has to land inside the dialog or Escape stays with the row.
            autofocus: true,
            key: const Key('uninstall-cancel'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
        if (_stage == _Stage.confirming && _canRun) _confirmButton(),
        if (_finished)
          FilledButton(
            autofocus: true,
            key: const Key('uninstall-close'),
            onPressed: () => Navigator.pop(context, _stage == _Stage.done),
            child: Text(_stage == _Stage.done ? '完成' : '关闭'),
          ),
      ],
    );
  }

  Widget _confirmButton() {
    if (widget.engine == UninstallEngine.bcu) {
      return FilledButton(
        key: const Key('bcu-open'),
        onPressed: _openBcu,
        child: const Text('打开 BCUninstaller'),
      );
    }

    return FilledButton(
      key: const Key('uninstall-confirm'),
      style: FilledButton.styleFrom(
        backgroundColor: TiColors.danger,
        foregroundColor: Colors.white,
      ),
      onPressed: _run,
      child: const Text('卸载'),
    );
  }

  String get _title => switch (_stage) {
    _Stage.done => '卸载完成',
    _Stage.failed => '卸载失败',
    _Stage.running => '正在卸载 ${widget.app.name}',
    _Stage.preparing => '正在读取注册表',
    _Stage.confirming =>
      widget.engine == UninstallEngine.bcu
          ? '在 BCUninstaller 里清理 ${widget.app.name}？'
          : '卸载 ${widget.app.name}？',
  };

  List<String> get _lines => switch (_stage) {
    _Stage.failed => [_error?.toString() ?? '卸载器没有给出原因。'],
    _Stage.done => ['${widget.app.name} 的卸载命令已经跑完。'],
    _Stage.running => [
      '${widget.app.id} · ${widget.app.version}',
      if (widget.engine == UninstallEngine.native) _entry!.preferred,
    ],
    _Stage.preparing => ['正在查这个程序登记的卸载命令。'],
    _Stage.confirming => _preview,
  };

  List<String> get _preview {
    final app = widget.app;
    final details = '${app.id} · ${app.version}';

    return switch (widget.engine) {
      UninstallEngine.winget => [
        details,
        ref.read(wingetProvider).uninstallCommand(app).join(' '),
        'winget 会以静默模式运行，过程可能要一会儿。',
      ],
      UninstallEngine.native =>
        _entry == null
            ? [details, '这个程序没有登记卸载命令。']
            : [details, _entry!.preferred, '这是程序自己登记的命令，它可能还会弹自己的确认框。'],
      UninstallEngine.bcu => [
        details,
        widget.bcu!.directory,
        '深度清理在 BCUninstaller 自己的窗口里完成，我们只负责打开它。',
      ],
    };
  }
}
