import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coin/coin_provider.dart';
import '../coin/shop.dart';
import '../mascot/mascot_models.dart';
import '../mascot/mascot_widget.dart';
import '../theme/ukalab_palette.dart';
import 'outfit_models.dart';
import 'outfit_provider.dart';
import 'outfit_service.dart';

/// 着られない理由の文言。
String outfitLockedReason(OutfitAvailability a, {int price = 0}) {
  switch (a) {
    case OutfitAvailability.available:
      return '';
    case OutfitAvailability.notPurchased:
      return '$priceコインで購入できます';
    case OutfitAvailability.notPassed:
      return '合格したときに解放されます';
    case OutfitAvailability.noExamDate:
      return '試験日を設定すると着られます';
    case OutfitAvailability.notReady:
      return '準備完了の目標を達成すると解放されます';
  }
}

/// 衣装のショップ・着替え画面（資格1つぶん）。
///
/// コインは学習の成長でだけ増える（課金・広告では増えない）。衣装は見た目だけで、
/// 学習の内容には影響しない。`coinServiceProvider` の `shop` に
/// `OutfitCatalog.shopItems([cert])` を渡しておくこと。
class WardrobeScreen extends ConsumerWidget {
  const WardrobeScreen({
    super.key,
    required this.cert,
    this.examPhase = ExamPhase.none,
    this.stage = MascotStage.lv1,
    this.pack = CharacterPack.standard,
    this.title = '着替え・ショップ',
  });

  final UkalabCert cert;
  final ExamPhase examPhase;
  final MascotStage stage;
  final CharacterPack pack;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coin = ref.watch(coinProvider);
    final outfit = ref.watch(outfitProvider);
    final service = ref.read(outfitServiceProvider);
    final theme = Theme.of(context);

    Future<void> buy(Outfit o) async {
      final r = await ref.read(coinProvider.notifier).purchase(o.id);
      if (!context.mounted) return;
      final msg = switch (r) {
        PurchaseResult.purchased => '${o.name}を購入しました',
        PurchaseResult.insufficient => 'コインが足りません。学習すると貯まります',
        PurchaseResult.alreadyOwned => 'すでに持っています',
        PurchaseResult.unknownItem => '購入できません',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }

    Future<void> wear(Outfit o) async {
      final ok = await ref.read(outfitProvider.notifier).equip(o.id, examPhase: examPhase);
      if (!context.mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('この衣装は今は着られません')));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: MascotWidget(
                pack: pack,
                stage: stage,
                outfit: outfit.equipped,
                examPhase: examPhase,
                size: 140,
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text('学習コイン ${coin.balance}', style: theme.textTheme.titleMedium)),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'コインは学習で貯まります。衣装は見た目だけで、学習の内容には影響しません。',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            for (final o in OutfitCatalog.forCert(cert)) ...[
              _OutfitTile(
                outfit: o,
                availability: service.availability(o, purchasedIds: coin.owned, examPhase: examPhase),
                wearing: outfit.equipped?.id == o.id,
                onBuy: () => buy(o),
                onWear: () => wear(o),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _OutfitTile extends StatelessWidget {
  const _OutfitTile({
    required this.outfit,
    required this.availability,
    required this.wearing,
    required this.onBuy,
    required this.onWear,
  });

  final Outfit outfit;
  final OutfitAvailability availability;
  final bool wearing;
  final VoidCallback onBuy;
  final VoidCallback onWear;

  @override
  Widget build(BuildContext context) {
    final available = availability == OutfitAvailability.available;
    final Widget trailing;
    if (wearing) {
      trailing = const Icon(Icons.check_circle);
    } else if (available) {
      trailing = OutlinedButton(onPressed: onWear, child: const Text('着る'));
    } else if (availability == OutfitAvailability.notPurchased) {
      trailing = FilledButton(onPressed: onBuy, child: Text('${outfit.price}コイン'));
    } else {
      trailing = const Icon(Icons.lock_outline);
    }
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(outfit.name),
        subtitle: Text(
          wearing
              ? '着ています'
              : available
                  ? '着られます'
                  : outfitLockedReason(availability, price: outfit.price),
        ),
        trailing: trailing,
      ),
    );
  }
}
