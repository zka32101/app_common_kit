import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FakeEntitlementService> _pump(WidgetTester tester, {EntitlementState initial = EntitlementState.free}) async {
  final service = FakeEntitlementService(
    initial: initial,
    availableOffers: const [
      EntitlementOffer(id: 'noads', productId: 'p_noads', title: '広告非表示', priceString: '¥480'),
    ],
    grantOnPurchase: const {'p_noads': EntitlementState(hasNoAds: true)},
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [entitlementServiceProvider.overrideWithValue(service)],
    child: const MaterialApp(home: Scaffold(body: PurchaseSection())),
  ));
  await tester.pump();
  await tester.pump();
  return service;
}

void main() {
  testWidgets('未購入なら商品と価格が並び、購入すると購入済み表示になる', (tester) async {
    await _pump(tester);
    expect(find.text('広告非表示'), findsOneWidget);
    await tester.tap(find.text('¥480'));
    await tester.pump();
    await tester.pump();
    expect(find.text('購入しました。'), findsOneWidget);
    expect(find.text('広告非表示を購入済みです'), findsOneWidget);
  });

  testWidgets('購入済みなら商品は出さず、復元ボタンは残る', (tester) async {
    await _pump(tester, initial: const EntitlementState(hasPremium: true));
    expect(find.text('プレミアムを購入済みです'), findsOneWidget);
    expect(find.text('¥480'), findsNothing);
    expect(find.text('購入を復元'), findsOneWidget);
  });
}
