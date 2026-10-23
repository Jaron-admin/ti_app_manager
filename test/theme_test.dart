import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/design/theme.dart';
import 'package:ti_app_manager/design/tokens.dart';

void main() {
  test('light theme uses Ti tokens', () {
    final theme = TiTheme.light();

    expect(theme.scaffoldBackgroundColor, TiColors.paper);
    expect(theme.colorScheme.primary, TiColors.primary);
    expect(theme.colorScheme.surface, TiColors.surface);
  });

  test('dark theme uses Ti dark tokens', () {
    final theme = TiTheme.dark();

    expect(theme.scaffoldBackgroundColor, TiColors.paperDark);
    expect(theme.colorScheme.primary, TiColors.primaryDark);
    expect(theme.colorScheme.surface, TiColors.surfaceDark);
  });
}
