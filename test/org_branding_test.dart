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

  testWidgets('appIconAsset と backgroundColor を渡すと、アイコンと背景色が出る', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: StartupSplash(
        appIconAsset: 'assets/branding/yourwish_logo.png',
        backgroundColor: Color(0xFF123456),
      ),
    ));
    final assets = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => (i.image as AssetImage).assetName)
        .toList();
    expect(assets, contains('assets/branding/yourwish_logo.png'));
    expect(find.byType(OrgBrandingFooter), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFF123456),
    );
  });

  testWidgets('引数なしなら従来表示（アイコンなし・背景色指定なし）', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupSplash()));
    expect(find.byType(Image), findsOneWidget); // 組織ロゴだけ
    expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, isNull);
  });
}
