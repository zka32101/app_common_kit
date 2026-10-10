import 'package:flutter/material.dart';

/// カード一覧を分類する見出し。ホーム画面などで、同形のカードが
/// フラットに並ぶのを避けるために使う。
///
/// `SectionHeader` という名前は既存アプリ側のウィジェットと衝突しやすいため、
/// キット内では `Kit` を付けて区別する。
class KitSectionHeader extends StatelessWidget {
  const KitSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
