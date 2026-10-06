import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('起動画面の下部に組織ロゴが出る', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupSplash()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(OrgBrandingFooter), findsOneWidget);
    expect(find.bySemanticsLabel('Your Wish'), findsOneWidget);
    // ロゴは画面の下半分にある。
    final y = tester.getCenter(find.byType(Image)).dy;
    expect(y, greaterThan(tester.view.physicalSize.height / tester.view.devicePixelRatio / 2));
    expect(tester.takeException(), isNull);
  });
}
