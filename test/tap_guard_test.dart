import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('duration 未指定のテスト環境では無効（アプリのテストは変更不要）', (t) async {
    KitTapGuard.duration = null;
    var n = 0;
    Widget w(String x) => MaterialApp(home: Scaffold(body: ChoiceTile(label: 'A', text: x, state: ChoiceState.idle, onTap: () => n++)));
    await t.pumpWidget(w('q1'));
    await t.pumpWidget(w('q2'));
    await t.tap(find.text('q2'));
    expect(n, 1);
    KitTapGuard.duration = KitTapGuard.defaultDuration;
  });

  setUp(() => KitTapGuard.duration = KitTapGuard.defaultDuration);
  tearDown(() {
    KitTapGuard.duration = null;
    KitTapGuard.guardOnFirstShow = false;
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

  for (final hands in [false, true]) {
    final name = hands ? 'HandsFreeChoiceTile' : 'ChoiceTile';
    Widget tile(String text, ChoiceState st, VoidCallback onTap, {String label = 'A'}) => hands
        ? HandsFreeChoiceTile(label: label, text: text, state: st, onTap: onTap)
        : ChoiceTile(label: label, text: text, state: st, onTap: onTap);

    group(name, () {
      testWidgets('初回マウント直後はガードしない', (t) async {
        var n = 0;
        await t.pumpWidget(host(tile('q1', ChoiceState.idle, () => n++)));
        await t.tap(find.text('q1'));
        expect(n, 1);
      });

      testWidgets('問題切替直後は無視し、時間経過後は受け付ける', (t) async {
        var n = 0;
        await t.pumpWidget(host(tile('q1', ChoiceState.idle, () => n++)));
        await t.pumpWidget(host(tile('q2', ChoiceState.idle, () => n++)));
        await t.tap(find.text('q2'));
        expect(n, 0);
        await t.pump(const Duration(milliseconds: 449));
        await t.tap(find.text('q2'));
        expect(n, 0);
        await t.pump(const Duration(milliseconds: 2));
        await t.tap(find.text('q2'));
        expect(n, 1);
      });

      testWidgets('同一問題内の state 変化ではガードしない', (t) async {
        var n = 0;
        await t.pumpWidget(host(tile('q1', ChoiceState.idle, () => n++)));
        await t.pumpWidget(host(tile('q1', ChoiceState.selected, () => n++)));
        await t.tap(find.text('q1'));
        await t.pumpWidget(host(tile('q1', ChoiceState.correct, () => n++)));
        await t.tap(find.text('q1'));
        expect(n, 2);
      });

      testWidgets('問題切替のたびに再ガードする', (t) async {
        var n = 0;
        await t.pumpWidget(host(tile('q1', ChoiceState.idle, () => n++)));
        await t.pumpWidget(host(tile('q2', ChoiceState.idle, () => n++)));
        await t.pump(const Duration(milliseconds: 500));
        await t.pumpWidget(host(tile('q3', ChoiceState.idle, () => n++)));
        await t.tap(find.text('q3'));
        expect(n, 0);
        await t.pump(const Duration(milliseconds: 500));
        await t.tap(find.text('q3'));
        expect(n, 1);
      });

      testWidgets('KitTapGuard.duration=zero で無効', (t) async {
        KitTapGuard.duration = Duration.zero;
        var n = 0;
        await t.pumpWidget(host(tile('q1', ChoiceState.idle, () => n++)));
        await t.pumpWidget(host(tile('q2', ChoiceState.idle, () => n++)));
        await t.tap(find.text('q2'));
        expect(n, 1);
      });

      testWidgets('guardOnFirstShow=true なら初回もガードする', (t) async {
        KitTapGuard.guardOnFirstShow = true;
        var n = 0;
        await t.pumpWidget(host(tile('q1', ChoiceState.idle, () => n++)));
        await t.tap(find.text('q1'));
        expect(n, 0);
        await t.pump(const Duration(milliseconds: 500));
        await t.tap(find.text('q1'));
        expect(n, 1);
      });

      testWidgets('ガード中も Semantics は button のまま', (t) async {
        final h = t.ensureSemantics();
        await t.pumpWidget(host(tile('q1', ChoiceState.idle, () {})));
        await t.pumpWidget(host(tile('q2', ChoiceState.idle, () {})));
        final sem = t.getSemantics(find.byType(hands ? HandsFreeChoiceTile : ChoiceTile));
        expect(sem.flagsCollection.isButton, isTrue);
        expect(sem.label, contains('q2'));
        await t.pump(const Duration(seconds: 1));
        h.dispose();
      });
    });
  }
}
