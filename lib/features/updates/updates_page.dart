import 'package:flutter/material.dart';

import '../../design/components/ti_empty.dart';
import '../../design/components/ti_page.dart';

class UpdatesPage extends StatelessWidget {
  const UpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TiPage(
      key: Key('page-updates'),
      title: '可更新',
      subtitle: '让软件保持在最新版本',
      child: TiEmpty(
        icon: Icons.arrow_circle_up_outlined,
        title: '暂无更新信息',
        message: '检查更新后，可升级的软件会显示在这里。',
      ),
    );
  }
}
