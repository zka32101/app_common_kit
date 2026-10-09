import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('未設定なら案内を出し、設定済みなら日付と解除ボタンを出す', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ExamDateTile(date: null, onChanged: (_) {})),
    ));
    expect(find.textContaining('未設定'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ExamDateTile(date: DateTime(2026, 11, 22), onChanged: (_) {})),
    ));
    expect(find.text('2026/11/22'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);
  });

  testWidgets('解除ボタンで null を返す', (tester) async {
    DateTime? got = DateTime(2000);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ExamDateTile(date: DateTime(2026, 11, 22), onChanged: (v) => got = v)),
    ));
    await tester.tap(find.byIcon(Icons.clear));
    expect(got, isNull);
  });

  testWidgets('ピッカーで選んだ日付を返す', (tester) async {
    DateTime? got;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ExamDateTile(date: null, now: DateTime(2026, 11, 1), onChanged: (v) => got = v),
      ),
    ));
    await tester.tap(find.text('受験日'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(got, DateTime(2026, 11, 1));
  });
}
