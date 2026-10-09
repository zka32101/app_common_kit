import 'package:flutter/material.dart';

/// 受験日の入力欄。日付ピッカーで選び、解除もできる。
///
/// 状態は持たない。保存は呼び出し側（[onChanged] で受け取り、アプリ側の保存先へ書く）。
/// 入れた日付は、試験直前モードなどの判定に使う。
class ExamDateTile extends StatelessWidget {
  const ExamDateTile({super.key, required this.date, required this.onChanged, this.now});

  /// 現在の受験日。未設定なら null。
  final DateTime? date;

  /// 日付を選んだとき、解除したとき（null）に呼ばれる。
  final ValueChanged<DateTime?> onChanged;

  /// 「今日」。テスト用。省くと現在時刻。
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final d = date;
    return ListTile(
      leading: const Icon(Icons.event),
      title: const Text('受験日'),
      subtitle: Text(
        d == null ? '未設定。入力すると直前の復習モードが使えます。' : '${d.year}/${d.month}/${d.day}',
      ),
      trailing: d == null
          ? null
          : IconButton(
              tooltip: '受験日を解除',
              icon: const Icon(Icons.clear),
              onPressed: () => onChanged(null),
            ),
      onTap: () async {
        final today = now ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: d ?? today,
          firstDate: DateTime(today.year, today.month, today.day),
          lastDate: DateTime(today.year + 3, 12, 31),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
