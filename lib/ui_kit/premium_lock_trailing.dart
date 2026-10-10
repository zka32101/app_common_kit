import 'package:flutter/material.dart';

import 'kit_strings.dart';

/// プレミアム限定カードの trailing。未購入なら鍵アイコンを添えて、
/// タップする前から有料だと分かるようにする。
class PremiumLockTrailing extends StatelessWidget {
  const PremiumLockTrailing({super.key, required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    if (isPremium) return const Icon(Icons.chevron_right);
    final s = KitStrings.of(context);
    return Semantics(
      label: s.premiumLocked,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 18,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
