import 'dart:convert';

import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'coin': 120,
      'coin_log': ['a', 'b'],
      'theme': 'dark',
      'secret_token': 'xyz',
    }),
  );

  BackupService make({DateTime? now}) => BackupService(
    appId: 'kanken',
    clock: () => now ?? DateTime.utc(2026, 10, 14),
    sources: [
      SharedPreferencesBackupSource('wallet', keys: {'coin', 'coin_log'}),
      SharedPreferencesBackupSource('settings', prefixes: ['the']),
    ],
  );

  test('書き出して別の端末に復元できる。対象外のキーは含めない', () async {
    final json = await make().exportJson();
    final m = jsonDecode(json) as Map;
    expect(m['appId'], 'kanken');
    expect(json.contains('secret_token'), isFalse);

    SharedPreferences.setMockInitialValues({});
    final r = await make().restoreJson(json);
    expect(r.ok, isTrue);
    expect(r.restored, ['wallet', 'settings']);
    final p = await SharedPreferences.getInstance();
    expect(p.getInt('coin'), 120);
    expect(p.getStringList('coin_log'), ['a', 'b']);
    expect(p.getString('theme'), 'dark');
    expect(p.getString('secret_token'), isNull);
  });

  test('バックアップに細工された対象外キーは書き込まない', () async {
    final json = jsonEncode({
      'format': 1,
      'appId': 'kanken',
      'sections': {
        'wallet': {'coin': 5, 'secret_token': 'evil'},
      },
    });
    final r = await make().restoreJson(json);
    expect(r.restored, ['wallet']);
    expect(r.skipped, ['settings']);
    final p = await SharedPreferences.getInstance();
    expect(p.getInt('coin'), 5);
    expect(p.getString('secret_token'), 'xyz');
  });

  test('別アプリ・新しい形式・壊れた JSON は拒否する', () async {
    final svc = make();
    expect(() => svc.restoreJson('{'), throwsA(isA<BackupFormatException>()));
    expect(() => svc.restoreJson('[]'), throwsA(isA<BackupFormatException>()));
    expect(
      () => svc.restoreJson(
        jsonEncode({'format': 1, 'appId': 'other', 'sections': {}}),
      ),
      throwsA(isA<BackupFormatException>()),
    );
    expect(
      () => svc.restoreJson(
        jsonEncode({'format': 99, 'appId': 'kanken', 'sections': {}}),
      ),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('失敗した区画があっても他は続ける', () async {
    final svc = BackupService(
      appId: 'kanken',
      sources: [
        CallbackBackupSource(
          'bad',
          onExport: () async => 1,
          onRestore: (_) async => throw StateError('x'),
        ),
        CallbackBackupSource(
          'good',
          onExport: () async => 2,
          onRestore: (_) async {},
        ),
      ],
    );
    final r = await svc.restoreJson(await svc.exportJson());
    expect(r.ok, isFalse);
    expect(r.failed.keys, ['bad']);
    expect(r.restored, ['good']);
  });
}
