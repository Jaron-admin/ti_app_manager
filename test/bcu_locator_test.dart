import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/shared/bcu_locator.dart';

void main() {
  BcuLocator locate(Set<String> files, {Map<String, String>? environment}) =>
      BcuLocator(
        environment:
            environment ??
            const {
              'ProgramFiles': r'C:\Program Files',
              r'ProgramFiles(x86)': r'C:\Program Files (x86)',
            },
        fileExists: files.contains,
      );

  test('finds the installed copy under program files', () {
    final bcu = locate({
      r'C:\Program Files\BCUninstaller\BCUninstaller.exe',
    }).find();

    expect(bcu?.directory, r'C:\Program Files\BCUninstaller');
    expect(bcu?.guiExe, r'C:\Program Files\BCUninstaller\BCUninstaller.exe');
  });

  test('also looks in the 32-bit program files folder', () {
    final bcu = locate({
      r'C:\Program Files (x86)\BCUninstaller\BCUninstaller.exe',
    }).find();

    expect(bcu?.directory, r'C:\Program Files (x86)\BCUninstaller');
  });

  test('reports nothing when the folder is empty', () {
    expect(locate({}).find(), isNull);
    expect(locate({}, environment: const {}).find(), isNull);
  });
}
