import 'package:flutter/material.dart';

import '../../app/app_info.dart';
import '../../design/components/ti_card.dart';
import '../../design/components/ti_page.dart';
import '../../design/tokens.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TiPage(
      key: const Key('page-about'),
      title: '关于',
      subtitle: '${AppInfo.name} ${AppInfo.version}',
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(label: '当前平台', value: 'Windows 10 / 11'),
                      _InfoRow(label: '安装与更新', value: 'winget'),
                      _InfoRow(
                        label: '深度卸载',
                        value: 'BCUninstaller（Apache 2.0）',
                      ),
                      _InfoRow(label: '数据处理', value: '全部在本机完成，不上传任何信息'),
                    ],
                  ),
                ),
                const SizedBox(height: TiSpace.card),
                Text(
                  'macOS 版本会在 Windows 版本稳定后评估。',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: TiSpace.gap / 2),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
