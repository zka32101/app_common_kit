import 'package:app_common_kit/app_common_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const noAds = EntitlementState(hasNoAds: true);
  final premium = EntitlementState(
    hasPremium: true,
    premiumExpiresAt: DateTime(2027, 1, 1),
  );

  test('free は広告表示、noads/premium は非表示', () {
    expect(EntitlementState.free.adsHidden, isFalse);
    expect(noAds.adsHidden, isTrue);
    expect(premium.adsHidden, isTrue);
  });

  test('購入成功で状態が更新されストリームに流れる', () async {
    final s = FakeEntitlementService(grantOnPurchase: {'noads_480': noAds});
    final events = <EntitlementState>[];
    s.stateStream.listen(events.add);
    expect(await s.purchase('noads_480'), PurchaseOutcome.success);
    await Future<void>.delayed(Duration.zero);
    expect(s.state, noAds);
    expect(events, [noAds]);
  });

  test('未知の商品は failed で状態不変', () async {
    final s = FakeEntitlementService();
    expect(await s.purchase('x'), PurchaseOutcome.failed);
    expect(s.state, EntitlementState.free);
  });

  test('beforePurchase が false なら購入されない（保護者ゲート）', () async {
    final s = FakeEntitlementService(
      beforePurchase: (_) async => false,
      grantOnPurchase: {'noads_480': noAds},
    );
    expect(await s.purchase('noads_480'), PurchaseOutcome.blockedByGate);
    expect(s.state.hasNoAds, isFalse);
  });

  test('restore で購入が復元される', () async {
    final s = FakeEntitlementService()..restorable = premium;
    expect((await s.restore()).hasPremium, isTrue);
  });

  test('adsHiddenProvider が状態に追従する', () async {
    final s = FakeEntitlementService(grantOnPurchase: {'p': premium});
    final c = ProviderContainer(
      overrides: [entitlementServiceProvider.overrideWithValue(s)],
    );
    addTearDown(c.dispose);
    c.listen(entitlementStateProvider, (_, __) {});
    expect(c.read(adsHiddenProvider), isFalse);
    await s.purchase('p');
    await Future<void>.delayed(Duration.zero);
    expect(c.read(adsHiddenProvider), isTrue);
  });

  group('offers', () {
    const offer = EntitlementOffer(
      id: r'$rc_monthly',
      productId: 'premium-monthly',
      title: '月額',
      priceString: '¥300',
    );

    test('offers を返し、purchaseOffer で購入できる', () async {
      final s = FakeEntitlementService(
        availableOffers: [offer],
        grantOnPurchase: {'premium-monthly': noAds},
      );
      expect((await s.offers()).single.priceString, '¥300');
      expect(await s.purchaseOffer(offer.id), PurchaseOutcome.success);
      expect(s.state.hasNoAds, isTrue);
    });

    test('未知の offerId は failed', () async {
      final s = FakeEntitlementService(availableOffers: [offer]);
      expect(await s.purchaseOffer('nope'), PurchaseOutcome.failed);
    });

    test('purchaseOffer も beforePurchase に止められる', () async {
      final s = FakeEntitlementService(
        availableOffers: [offer],
        beforePurchase: (_) async => false,
        grantOnPurchase: {'premium-monthly': noAds},
      );
      expect(await s.purchaseOffer(offer.id), PurchaseOutcome.blockedByGate);
    });
  });
}
