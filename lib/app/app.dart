import 'package:flutter/material.dart';

import '../design/theme.dart';
import 'app_info.dart';
import 'shell.dart';

class TiApp extends StatelessWidget {
  const TiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: TiTheme.light(),
      darkTheme: TiTheme.dark(),
      themeMode: ThemeMode.system,
      home: const TiShell(),
    );
  }
}
