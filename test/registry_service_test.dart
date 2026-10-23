import 'package:flutter_test/flutter_test.dart';
import 'package:ti_app_manager/shared/process_runner.dart';
import 'package:ti_app_manager/shared/registry_service.dart';

import 'support/fake_process_runner.dart';

void main() {
  group('arpKeyPath', () {
    test('maps the winget arp id onto the registry view it came from', () {
      expect(
        arpKeyPath(r'ARP\Machine\X64\AbleHorse'),
        r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AbleHorse',
      );
      expect(
        arpKeyPath(r'ARP\Machine\X86\Google Chrome'),
        r'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome',
      );
      expect(
        arpKeyPath(r'ARP\User\X64\0257f8863d4ebf4ebf2d5c0a828395a9'),
        r'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\0257f8863d4ebf4ebf2d5c0a828395a9',
      );
    });

    test('ignores ids that are not registry entries', () {
      expect(arpKeyPath(r'MSIX\AdvancedMicroDevicesInc_22.10.0.0'), isNull);
      expect(arpKeyPath('7zip.7zip'), isNull);
      expect(arpKeyPath(r'ARP\Machine'), isNull);
    });
  });

  group('RegistryService', () {
    test('asks powershell for both uninstall strings as utf-8', () async {
      final runner = FakeProcessRunner(
        const CommandResult(
          exitCode: 0,
          stdoutText: '\t"C:\\Program Files\\AbleHorse\\unins000.exe"\n',
        ),
      );

      final entry = await RegistryService(runner: runner).uninstaller(r'ARP\Machine\X64\AbleHorse');

      final command = runner.calls.single;
      expect(command.first, 'powershell');
      expect(command, contains('-NoProfile'));
      final script = command.last;
      expect(script, contains('[Console]::OutputEncoding=[Text.Encoding]::UTF8'));
      expect(
        script,
        contains(
          r"""'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\AbleHorse'""",
        ),
      );
      expect(entry?.command, r'"C:\Program Files\AbleHorse\unins000.exe"');
      expect(entry?.quietCommand, isEmpty);
      expect(entry?.preferred, entry?.command);
    });

    test('prefers the silent string when the app registers one', () async {
      final runner = FakeProcessRunner(
        const CommandResult(
          exitCode: 0,
          stdoutText: 'msiexec /x {GUID} /quiet\tuninstall.exe /S\n',
        ),
      );

      final entry = await RegistryService(runner: runner).uninstaller(r'ARP\Machine\X64\Foo');

      expect(entry?.command, r'uninstall.exe /S');
      expect(entry?.quietCommand, r'msiexec /x {GUID} /quiet');
      expect(entry?.preferred, r'msiexec /x {GUID} /quiet');
    });

    test('escapes a quote in a key name instead of breaking out of it', () async {
      final runner = FakeProcessRunner(
        const CommandResult(exitCode: 0, stdoutText: '\t\n'),
      );

      await RegistryService(runner: runner).uninstaller(r"ARP\Machine\X64\It's Foo");

      expect(runner.calls.single.last, contains(r"It''s Foo"));
      expect(runner.calls.single.last, contains('Get-ItemProperty'));
    });

    test('gives up on a key that has no uninstaller', () async {
      final service = RegistryService(
        runner: FakeProcessRunner(
          const CommandResult(exitCode: 0, stdoutText: '\t\n'),
        ),
      );

      expect(await service.uninstaller(r'ARP\Machine\X64\Foo'), isNull);
      expect(await service.uninstaller('7zip.7zip'), isNull);
    });

    test('reports a missing key as no uninstaller, not as an error', () async {
      final service = RegistryService(
        runner: FakeProcessRunner(
          const CommandResult(
            exitCode: 1,
            stdoutText: '',
            stderrText: 'Cannot find path because it does not exist.',
          ),
        ),
      );

      expect(await service.uninstaller(r'ARP\Machine\X64\Foo'), isNull);
    });
  });

  group('splitUninstallCommand', () {
    test('splits a quoted executable from its arguments', () {
      final split = splitUninstallCommand(
        r'"C:\Program Files\Foo\unins000.exe" /SILENT',
      );

      expect(split?.exe, r'C:\Program Files\Foo\unins000.exe');
      expect(split?.args, ['/SILENT']);
    });

    test('finds the executable even when the path is not quoted', () {
      final split = splitUninstallCommand(
        r'C:\Program Files\Foo\uninstall.exe /uninstall',
      );

      expect(split?.exe, r'C:\Program Files\Foo\uninstall.exe');
      expect(split?.args, ['/uninstall']);
    });

    test('keeps an msiexec argument that contains a guid', () {
      final split = splitUninstallCommand(r'MsiExec.exe /X{1234-5678}');

      expect(split?.exe, 'MsiExec.exe');
      expect(split?.args, ['/X{1234-5678}']);
    });

    test('refuses a command with no executable', () {
      expect(splitUninstallCommand('   '), isNull);
    });
  });
}
