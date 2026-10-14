import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _entries = [
  WhatsNewEntry(version: '1.1.0', items: ['A']),
  WhatsNewEntry(version: '1.2.0', items: ['B', 'C']),
  WhatsNewEntry(version: '2.0.0', items: ['D']),
];

void main() {
  test('compareVersions は数値で比較し +build を無視する', () {
    expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
    expect(compareVersions('1.2', '1.2.0'), 0);
    expect(compareVersions('1.2.0+5', '1.2.0'), 0);
    expect(compareVersions('1.2.0-beta', '1.2.0'), 0);
  });

  test('初回インストールは何も出さず記録する', () async {
    final store = InMemoryWhatsNewStore();
    final w = WhatsNew(
      store: store,
      currentVersion: '1.2.0',
      entries: _entries,
    );
    expect(await w.pending(), isEmpty);
    expect(await store.loadSeenVersion(), '1.2.0');
  });

  test('更新後は保存済みより新しく現在以下を新しい順に返す', () async {
    final store = InMemoryWhatsNewStore();
    await store.saveSeenVersion('1.0.0');
    final w = WhatsNew(
      store: store,
      currentVersion: '1.2.0',
      entries: _entries,
    );
    final p = await w.pending();
    expect(p.map((e) => e.version), ['1.2.0', '1.1.0']);
    await w.markSeen();
    expect(await w.pending(), isEmpty);
  });

  test('同じバージョンなら出さない', () async {
    final store = InMemoryWhatsNewStore();
    await store.saveSeenVersion('1.2.0');
    final w = WhatsNew(
      store: store,
      currentVersion: '1.2.0',
      entries: _entries,
    );
    expect(await w.pending(), isEmpty);
  });

  testWidgets('ダイアログを出して閉じると記録する', (tester) async {
    final store = InMemoryWhatsNewStore();
    await store.saveSeenVersion('1.0.0');
    final w = WhatsNew(
      store: store,
      currentVersion: '1.2.0',
      entries: _entries,
    );
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold();
          },
        ),
      ),
    );
    final f = showWhatsNewIfNeeded(
      ctx,
      w,
      strings: WhatsNewStrings.forLocale(const Locale('ja')),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    expect(find.text('新しくなりました'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(await f, isTrue);
    expect(await store.loadSeenVersion(), '1.2.0');
  });

  testWidgets('WhatsNewGate は更新後の初回だけ表示する', (tester) async {
    final store = InMemoryWhatsNewStore();
    await store.saveSeenVersion('1.0.0');
    final w = WhatsNew(
      store: store,
      currentVersion: '1.2.0',
      entries: _entries,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WhatsNewGate(
          whatsNew: w,
          strings: WhatsNewStrings.forLocale(const Locale('ja')),
          child: const Scaffold(body: Text('home')),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    expect(find.text('新しくなりました'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(await store.loadSeenVersion(), '1.2.0');
  });
}
