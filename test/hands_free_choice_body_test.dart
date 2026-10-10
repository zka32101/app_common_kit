import 'package:app_common_kit/app_common_kit.dart';
import 'package:app_common_kit/hands_free_tts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(ProviderContainer, FakeSpeechBackend)> _container({bool enabled = true}) async {
  final fake = FakeSpeechBackend();
  final c = ProviderContainer(overrides: [
    speechBackendProvider.overrideWithValue(fake),
    handsFreeStoreProvider.overrideWithValue(InMemoryHandsFreeStore()),
  ]);
  await c.read(handsFreeProvider.notifier).setEnabled(enabled);
  return (c, fake);
}

Widget _app(ProviderContainer c, {String qid = 'q1', void Function(int)? onSelect}) =>
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(
          body: HandsFreeChoiceBody(
            qid: qid,
            prompt: '1 + 1 = ?',
            choices: const ['2', '3'],
            index: 3,
            total: 10,
            onSelect: onSelect ?? (_) {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('表示すると問題文と選択肢を自動で読み上げる', (tester) async {
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await tester.pump();
    expect(find.text('問題 3 / 10'), findsOneWidget);
    expect(fake.spoken, hasLength(1));
    expect(fake.spoken.single, contains('1 + 1 = ?'));
  });

  testWidgets('同じ問題の再描画では読み直さず、問題が変わると読む', (tester) async {
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await tester.pump();
    await tester.pumpWidget(_app(c));
    await tester.pump();
    expect(fake.spoken, hasLength(1));
    await tester.pumpWidget(_app(c, qid: 'q2'));
    await tester.pump();
    expect(fake.spoken, hasLength(2));
  });

  testWidgets('モードが無効なら自動では読まないが、読み上げボタンは読む', (tester) async {
    final (c, fake) = await _container(enabled: false);
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await tester.pump();
    expect(fake.spoken, isEmpty);
    await tester.tap(find.byType(ReadAloudButton));
    await tester.pump();
    expect(fake.spoken, hasLength(1));
  });

  testWidgets('選択肢を押すと表示順の位置が返る', (tester) async {
    final (c, _) = await _container();
    addTearDown(c.dispose);
    int? picked;
    await tester.pumpWidget(_app(c, onSelect: (i) => picked = i));
    await tester.pump();
    await tester.tap(find.text('3'));
    expect(picked, 1);
  });

  testWidgets('画面を離れると読み上げを止める', (tester) async {
    final (c, fake) = await _container();
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await tester.pump();
    final before = fake.stopCount;
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(fake.stopCount, greaterThan(before));
  });

  test('flutter_tts の速さは、標準(1.0)を 0.5 に合わせて 0.1〜1.0 に収める', () {
    expect(FlutterTtsSpeechBackend.ttsRate(1.0), 0.5);
    expect(FlutterTtsSpeechBackend.ttsRate(0.1), 0.1);
    expect(FlutterTtsSpeechBackend.ttsRate(5.0), 1.0);
  });
}
