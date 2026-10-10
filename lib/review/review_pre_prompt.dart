import 'package:flutter/material.dart';

import '../ui_kit/kit_strings.dart';
import 'review_prompt.dart';

/// レビューを頼む前の確認ダイアログ（「アプリを楽しんでいますか？」）。
///
/// - 条件を満たしていなければ（[ReviewPromptService.evaluate] が `ask` 以外）、何も出さず false を返す
/// - 「はい」→ アプリ内のレビュー画面を出す（[ReviewPromptService.maybeRequest]）
/// - 「いいえ」→ レビューは頼まず、しばらく控える。[onNegative] で、フィードバック画面などへ案内できる
/// - 「あとで」→ 何もしない（頼んだことにはならない）
///
/// 良い体験の直後（合格・自己ベスト更新など）に呼ぶ。不具合の直後や学習の途中では呼ばない。
/// ダイアログは Navigator の上に積まれるので、呼び出し側の文言を使う（[strings] で上書きもできる）。
Future<bool> showReviewPrePrompt(
  BuildContext context,
  ReviewPromptService service, {
  VoidCallback? onNegative,
  KitStrings? strings,
}) async {
  if (service.evaluate() != ReviewDecision.ask) return false;
  final s = strings ?? KitStrings.of(context);
  final answer = await showDialog<_Answer>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.reviewEnjoyTitle),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(_Answer.later), child: Text(s.reviewLater)),
        TextButton(onPressed: () => Navigator.of(ctx).pop(_Answer.no), child: Text(s.reviewNo)),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(_Answer.yes), child: Text(s.reviewYes)),
      ],
    ),
  );
  switch (answer) {
    case _Answer.yes:
      await service.maybeRequest();
      return true;
    case _Answer.no:
      await service.declined();
      onNegative?.call();
      return true;
    case _Answer.later:
    case null:
      return true;
  }
}

enum _Answer { yes, no, later }
