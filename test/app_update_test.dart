import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('バージョン比較は数値で行う', () {
    expect(compareVersions('1.2.10', '1.2.9'), greaterThan(0));
    expect(compareVersions('1.0', '1.0.0'), 0);
    expect(compareVersions('1.0.0+5', '1.0.0'), 0);
    expect(compareVersions('1.9.0', '2.0.0'), lessThan(0));
  });

  test('判定: 強制・任意・なし', () {
    const p = UpdatePolicy(minVersion: '2.0.0', latestVersion: '2.1.0');
    expect(decideUpdate('1.9.9', p), UpdateDecision.required);
    expect(decideUpdate('2.0.0', p), UpdateDecision.optional);
    expect(decideUpdate('2.1.0', p), UpdateDecision.none);
    expect(decideUpdate('1.0.0', null), UpdateDecision.none);
  });

  test('取得に失敗しても none', () async {
    final r = await checkForUpdate(FakeUpdateBackend(null, fail: true), '1.0.0');
    expect(r.decision, UpdateDecision.none);
  });

  Future<void> open(WidgetTester t, UpdateBackend b, List<String?> opened) async {
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (c) => TextButton(
          onPressed: () => promptForUpdate(c, backend: b, currentVersion: '1.0.0', openStore: opened.add, strings: KitStrings.en),
          child: const Text('go'),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
  }

  testWidgets('強制: 閉じられず、押すとストアを開く', (t) async {
    final opened = <String?>[];
    await open(t, FakeUpdateBackend(const UpdatePolicy(minVersion: '2.0.0', storeUrl: 'u', message: '重要')), opened);
    expect(find.text('Update required'), findsOneWidget);
    expect(find.textContaining('重要'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    await t.tapAt(const Offset(2, 2));
    await t.pumpAndSettle();
    expect(find.text('Update required'), findsOneWidget);
    await t.tap(find.text('Update'));
    expect(opened, ['u']);
  });

  testWidgets('任意: あとでで閉じられる', (t) async {
    await open(t, FakeUpdateBackend(const UpdatePolicy(latestVersion: '1.1.0')), []);
    expect(find.text('A new version is available'), findsOneWidget);
    await t.tap(find.text('Later'));
    await t.pumpAndSettle();
    expect(find.text('A new version is available'), findsNothing);
  });

  testWidgets('更新なしなら何も出さない', (t) async {
    await open(t, FakeUpdateBackend(const UpdatePolicy(minVersion: '1.0.0')), []);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
