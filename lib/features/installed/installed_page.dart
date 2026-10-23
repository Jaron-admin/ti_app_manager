import 'package:flutter/material.dart';

import '../../design/components/ti_empty.dart';
import '../../design/components/ti_page.dart';

class InstalledPage extends StatelessWidget {
  const InstalledPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TiPage(
      key: Key('page-installed'),
      title: '已安装',
      subtitle: '这台电脑上的软件',
      child: TiEmpty(
        icon: Icons.inventory_2_outlined,
        title: '还没有软件清单',
        message: '读取完成后，软件会显示在这里。',
      ),
    );
  }
}
