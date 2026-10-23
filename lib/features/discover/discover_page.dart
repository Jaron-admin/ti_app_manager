import 'package:flutter/material.dart';

import '../../design/components/ti_empty.dart';
import '../../design/components/ti_page.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TiPage(
      key: Key('page-discover'),
      title: '发现',
      subtitle: '从 winget 搜索并安装软件',
      child: TiEmpty(
        icon: Icons.explore_outlined,
        title: '发现新软件',
        message: '输入软件名称，安装会直接在本机进行。',
      ),
    );
  }
}
