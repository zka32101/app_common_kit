import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fail implements DataEraser {
  @override
  String get id => 'fail';
  @override
  Future<void> erase() => throw StateError('x');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'a_1': 1, 'a_2': 2, 'keep': 3, 'b': 4}));

  test('SharedPreferencesEraser: 前置き・キーだけを消す', () async {
    await SharedPreferencesEraser(keys: {'b'}, prefixes: ['a_']).erase();
    final p = await SharedPreferences.getInstance();
    expect(p.getKeys(), {'keep'});
  });

  test('SharedPreferencesEraser: 指定が空なら何も消さない／all なら全部', () async {
    await SharedPreferencesEraser().erase();
    expect((await SharedPreferences.getInstance()).getKeys().length, 4);
    await SharedPreferencesEraser(all: true).erase();
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });

  test('ひとつ失敗しても残りを続け、結果にまとめる', () async {
    var called = false;
    final r = await DataDeletion([
      _Fail(),
      CallbackEraser('x', () async => called = true),
    ]).run();
    expect(called, isTrue);
    expect(r.ok, isFalse);
    expect(r.succeeded, ['x']);
    expect(r.failed.keys, ['fail']);
  });

  test('stopOnFailure なら最初の失敗で止める', () async {
    var called = false;
    final r = await DataDeletion([_Fail(), CallbackEraser('x', () async => called = true)],
        stopOnFailure: true).run();
    expect(called, isFalse);
    expect(r.succeeded, isEmpty);
  });

  test('文言: 5言語が空でなく、言語コードで選べる', () {
    for (final c in ['ja', 'en', 'zh', 'zh-Hant', 'ko']) {
      final s = DataDeletionStrings.forCode(c);
      for (final t in [s.menu, s.title, s.body, s.confirmCheck, s.cancel, s.delete, s.done, s.failed]) {
        expect(t, isNotEmpty);
      }
    }
    expect(DataDeletionStrings.forCode('en').delete, 'Delete');
    expect(DataDeletionStrings.forCode('xx').delete, DataDeletionStrings.ja.delete);
  });

  testWidgets('確認: チェックするまで削除できず、チェック後に削除が実行される', (tester) async {
    var ran = false;
    final deletion = DataDeletion([CallbackEraser('x', () async => ran = true)]);
    DeletionResult? result;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result =
                await showDataDeletionFlow(context, deletion, strings: DataDeletionStrings.ja),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final del = find.widgetWithText(TextButton, '削除する');
    expect(tester.widget<TextButton>(del).onPressed, isNull);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    expect(tester.widget<TextButton>(del).onPressed, isNotNull);
    await tester.tap(del);
    await tester.pumpAndSettle();
    expect(ran, isTrue);
    expect(result?.ok, isTrue);
    expect(find.text('データを削除しました'), findsOneWidget);
  });

  testWidgets('キャンセルなら何も消さず null', (tester) async {
    var ran = false;
    DeletionResult? result = const DeletionResult(succeeded: [], failed: {});
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showDataDeletionFlow(
                context, DataDeletion([CallbackEraser('x', () async => ran = true)]),
                strings: DataDeletionStrings.ja),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(ran, isFalse);
    expect(result, isNull);
  });
}
