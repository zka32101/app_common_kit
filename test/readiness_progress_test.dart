import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rule = ReadinessRule.standard;
  const half = MasteryInput(coverage: 0.7, accuracy: 0.7); // 0.49

  test('習得度が足りなければ、あと何%かが出る', () {
    final p = rule.progress(mastery: half, mockPassed: false);
    expect(p.isReady, isFalse);
    expect(p.masteryPercentLeft, 31);
    expect(p.mockNeeded, isTrue);
  });

  test('isReady と progress.isReady は一致する', () {
    const full = MasteryInput(coverage: 1, accuracy: 1);
    expect(rule.progress(mastery: full, mockPassed: true).isReady,
        rule.isReady(mastery: full, mockPassed: true));
    expect(rule.progress(mastery: full, mockPassed: false).isReady, isFalse);
  });

  testWidgets('カードは責めない文言で進み具合を出す', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ReadinessProgressCard(
            progress: rule.progress(mastery: half, mockPassed: false)),
      ),
    ));
    expect(find.text('習得度があと31%、模擬試験の合格でそろいます'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
