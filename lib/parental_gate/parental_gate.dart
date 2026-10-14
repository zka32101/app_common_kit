import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../entitlement/entitlement_service.dart';

/// 保護者ゲートの文言。内蔵: ja・en・zh・zh-Hant・ko（zh・zh-Hant・ko は機械翻訳の下書き。公開前に母語話者の確認が要る）。
class ParentalGateStrings {
  const ParentalGateStrings({
    required this.title,
    required this.description,
    required this.hint,
    required this.wrong,
    required this.ok,
    required this.cancel,
    required this.questionLabel,
  });

  final String title;
  final String description;
  final String hint;
  final String wrong;
  final String ok;
  final String cancel;

  /// 読み上げ用。`{a}`・`{op}`・`{b}` を、数と演算の語に置き換えて使う。
  final String questionLabel;

  /// `KitStrings.languageCode`（`ja`・`en`・`zh`・`zh-Hant`・`ko`）に合わせて選ぶ。それ以外は日本語。
  static ParentalGateStrings forCode(String code) => switch (code) {
        'en' => en,
        'zh' => zhHans,
        'zh-Hant' => zhHant,
        'ko' => ko,
        _ => ja,
      };

  static const ja = ParentalGateStrings(
    title: '保護者の方へ確認',
    description: 'これは大人の方が行う操作です。\n下の計算の答えを入力してください。',
    hint: '答えを入力',
    wrong: '答えが違います',
    ok: 'つぎへ',
    cancel: 'やめる',
    questionLabel: '{a} {op} {b} は？',
  );
  static const en = ParentalGateStrings(
    title: 'For parents',
    description: 'This step is for adults.\nEnter the answer to the sum below.',
    hint: 'Enter the answer',
    wrong: 'That is not the right answer',
    ok: 'Next',
    cancel: 'Cancel',
    questionLabel: '{a} {op} {b}?',
  );
  static const zhHans = ParentalGateStrings(
    title: '请家长确认',
    description: '此操作需由成年人进行。\n请输入下面算式的答案。',
    hint: '输入答案',
    wrong: '答案不正确',
    ok: '下一步',
    cancel: '取消',
    questionLabel: '{a} {op} {b} 等于多少？',
  );
  static const zhHant = ParentalGateStrings(
    title: '請家長確認',
    description: '此操作需由成年人進行。\n請輸入下面算式的答案。',
    hint: '輸入答案',
    wrong: '答案不正確',
    ok: '下一步',
    cancel: '取消',
    questionLabel: '{a} {op} {b} 等於多少？',
  );
  static const ko = ParentalGateStrings(
    title: '보호자 확인',
    description: '성인이 진행하는 단계입니다.\n아래 계산의 답을 입력해 주세요.',
    hint: '답 입력',
    wrong: '답이 틀렸습니다',
    ok: '다음',
    cancel: '취소',
    questionLabel: '{a} {op} {b}?',
  );
}

/// 保護者ゲートの問題。足し算か引き算（答えは必ず正の数）。
class ParentalGateQuestion {
  const ParentalGateQuestion(this.a, this.b, this.isAddition);

  final int a;
  final int b;
  final bool isAddition;

  int get answer => isAddition ? a + b : a - b;

  String get operator => isAddition ? '+' : '-';

  /// 10〜30 同士の足し算・引き算。子どもには少し難しく、大人なら瞬時に解ける程度。
  factory ParentalGateQuestion.random([math.Random? random]) {
    final r = random ?? math.Random();
    final add = r.nextBool();
    final x = 10 + r.nextInt(21);
    var y = 10 + r.nextInt(21);
    if (add) return ParentalGateQuestion(x, y, true);
    // 引き算は、答えが必ず1以上になるようにする（同じ数なら、片方をずらす）。
    if (x == y) y = x < 30 ? x + 1 : x - 1;
    return ParentalGateQuestion(math.max(x, y), math.min(x, y), false);
  }
}

/// 課金画面や外部ストア・外部サイトへ進む前に出す、軽量な保護者確認ダイアログ。
///
/// ランダムな足し算か引き算（答えは1以上）を出し、正解したときだけ `true` を返す。
/// **[maxAttempts] 回まちがえたら、`false` で閉じる**（当てずっぽうで通れないように）。
/// 使うときは [requireParentalGate] が簡単。
///
/// これは**簡易な確認**で、年齢確認や本人確認ではない。ストアの規約・各国の法令で、より強い確認が
/// 要るかどうかは、専門家の確認を経て決める。
class ParentalGateDialog extends StatefulWidget {
  const ParentalGateDialog({
    super.key,
    this.strings = ParentalGateStrings.ja,
    this.random,
    this.maxAttempts = 3,
  });

  final ParentalGateStrings strings;

  /// テストで問題を固定するための乱数。
  final math.Random? random;

  /// 何回まちがえたら閉じるか。
  final int maxAttempts;

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late final ParentalGateQuestion _q = ParentalGateQuestion.random(widget.random);
  final _controller = TextEditingController();
  int _wrong = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final input = int.tryParse(_controller.text.trim());
    if (input == _q.answer) {
      Navigator.pop(context, true);
      return;
    }
    _wrong++;
    if (_wrong >= widget.maxAttempts) {
      Navigator.pop(context, false);
      return;
    }
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final theme = Theme.of(context);
    final question = '${_q.a} ${_q.operator} ${_q.b} = ?';
    final spoken = s.questionLabel
        .replaceAll('{a}', '${_q.a}')
        .replaceAll('{op}', _q.isAddition ? '+' : '−')
        .replaceAll('{b}', '${_q.b}');
    return AlertDialog(
      // 文字を大きくした小さい画面でも、アイコン・題名・本文が切れずにスクロールできる
      scrollable: true,
      icon: const Icon(Icons.lock_outline),
      title: Text(s.title, textAlign: TextAlign.center),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.description, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Semantics(
              label: spoken,
              excludeSemantics: true,
              child: Text(question, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: s.hint,
                errorText: _wrong > 0 ? s.wrong : null,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
        FilledButton(onPressed: _submit, child: Text(s.ok)),
      ],
    );
  }
}

/// [ParentalGateDialog] を出し、正解したときだけ `true` を返す。
/// キャンセル・まちがいの上限・ダイアログを閉じた場合は `false`。
Future<bool> requireParentalGate(
  BuildContext context, {
  ParentalGateStrings strings = ParentalGateStrings.ja,
  math.Random? random,
  int maxAttempts = 3,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ParentalGateDialog(strings: strings, random: random, maxAttempts: maxAttempts),
  );
  return result ?? false;
}

/// 購入の前に保護者ゲートを出す [BeforePurchase]。
/// `RevenueCatEntitlementService.init(beforePurchase: parentalGateBeforePurchase(navigatorKey, strings: …))`
/// に渡す。ゲートを通らなければ購入しない。
///
/// `navigatorKey` は `MaterialApp(navigatorKey: …)` に渡したものを使う（購入のフックは `BuildContext` を持たないため）。
BeforePurchase parentalGateBeforePurchase(
  GlobalKey<NavigatorState> navigatorKey, {
  ParentalGateStrings strings = ParentalGateStrings.ja,
}) =>
    (productId) async {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return false;
      return requireParentalGate(context, strings: strings);
    };
