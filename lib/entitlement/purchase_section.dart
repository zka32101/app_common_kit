import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui_kit/kit_strings.dart';
import 'entitlement_provider.dart';
import 'entitlement_state.dart';

/// 設定タブに出す「購入」の欄。広告非表示・プレミアムの購入と、購入の復元。
/// 広告は noads / premium のどちらかを持つと自動的に非表示になる（`AdGate.adsHidden`）。
/// noads だけを持つ人には、プレミアムへのアップグレード（プレミアムの商品だけ）を出す。
///
/// [titleStyle] を省くと `titleMedium`。アプリごとの見出しの大きさに合わせて渡す。
class PurchaseSection extends ConsumerWidget {
  const PurchaseSection({super.key, this.titleStyle, this.isPremiumOffer = _defaultIsPremiumOffer});

  final TextStyle? titleStyle;

  /// プレミアムの商品か。既定は、ストアの商品IDに「premium」を含むこと（`<アプリ>_premium`）。
  final bool Function(EntitlementOffer offer) isPremiumOffer;

  static bool _defaultIsPremiumOffer(EntitlementOffer o) =>
      o.productId.toLowerCase().contains('premium');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementStateProvider).valueOrNull ?? EntitlementState.free;
    final service = ref.watch(entitlementServiceProvider);
    final s = KitStrings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.purchaseTitle, style: titleStyle ?? Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (entitlement.hasPremium)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(s.purchasedPremium),
          )
        else ...[
          // noads だけの人には、プレミアムの商品だけを出す（アップグレード）。
          if (entitlement.hasNoAds)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(s.purchasedNoAds),
            ),
          FutureBuilder<List<EntitlementOffer>>(
            future: service.offers(),
            builder: (context, snapshot) {
              final all = snapshot.data ?? const <EntitlementOffer>[];
              final offers = entitlement.hasNoAds ? all.where(isPremiumOffer).toList() : all;
              return Column(
                children: [
                  for (final offer in offers)
                    // ListTile の trailing だと、価格ボタンが文字拡大で幅いっぱいになり描画エラーになる。
                    // 入りきらないときは価格ボタンを次の行に回す。
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            Text(offer.title, style: Theme.of(context).textTheme.bodyLarge),
                            FilledButton(
                              onPressed: () => _purchase(context, ref, offer),
                              child: Text(offer.priceString),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        TextButton(
          onPressed: () => _restore(context, ref),
          child: Text(s.purchaseRestore),
        ),
      ],
    );
  }

  Future<void> _purchase(BuildContext context, WidgetRef ref, EntitlementOffer offer) async {
    final outcome = await ref.read(entitlementServiceProvider).purchaseOffer(offer.id);
    if (!context.mounted) return;
    final s = KitStrings.of(context);
    final message = switch (outcome) {
      PurchaseOutcome.success => s.purchaseSuccess,
      PurchaseOutcome.cancelled => s.purchaseCancelled,
      PurchaseOutcome.blockedByGate => s.purchaseBlocked,
      PurchaseOutcome.failed => s.purchaseFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final state = await ref.read(entitlementServiceProvider).restore();
    if (!context.mounted) return;
    final s = KitStrings.of(context);
    final message = state.adsHidden ? s.restoreDone : s.restoreNone;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
