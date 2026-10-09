import 'package:flutter/material.dart';

import 'choice_tile.dart';

/// 片手・ながら学習モード用の大きな選択肢ボタン。親指で押しやすいよう高さ 72pt 以上、
/// 文字も大きくする。色だけに頼らず、✓／✕のアイコンと文言も出す（[ChoiceTile] と同じ）。
class HandsFreeChoiceTile extends StatelessWidget {
  const HandsFreeChoiceTile({
    super.key,
    required this.label,
    required this.text,
    required this.state,
    this.onTap,
    this.correctText = '正解',
    this.incorrectText = '不正解',
  });

  /// 「ア」「A」「1」など。
  final String label;
  final String text;
  final ChoiceState state;
  final VoidCallback? onTap;
  final String correctText;
  final String incorrectText;

  /// ボタンの最小の高さ。
  static const minHeight = 72.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final success = dark ? const Color(0xFF5BD17F) : const Color(0xFF1E8E3E);

    Color border = theme.dividerColor;
    Color? bg;
    IconData? icon;
    Color? iconColor;
    String? mark;
    switch (state) {
      case ChoiceState.idle:
        break;
      case ChoiceState.selected:
        border = scheme.primary;
        bg = scheme.primary.withValues(alpha: 0.10);
        icon = Icons.radio_button_checked;
        iconColor = scheme.primary;
      case ChoiceState.correct:
        border = success;
        bg = success.withValues(alpha: 0.12);
        icon = Icons.check_circle;
        iconColor = success;
        mark = correctText;
      case ChoiceState.incorrect:
        border = scheme.error;
        bg = scheme.error.withValues(alpha: 0.12);
        icon = Icons.cancel;
        iconColor = scheme.error;
        mark = incorrectText;
    }

    return Semantics(
      button: onTap != null,
      selected: state == ChoiceState.selected,
      label: '$label。$text${mark == null ? '' : '。$mark'}',
      excludeSemantics: true,
      child: Material(
        color: bg ?? scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: state == ChoiceState.idle ? 1 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(label, style: theme.textTheme.titleLarge),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(text, style: theme.textTheme.titleMedium),
                        if (mark != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              mark,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: iconColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 12),
                    Icon(icon, color: iconColor, size: 28),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 読み上げボタン。押すと [onPressed] を呼ぶ（読み上げは [HandsFreeSpeaker.speakNow] など）。
/// タップ領域は 56pt。
class ReadAloudButton extends StatelessWidget {
  const ReadAloudButton({
    super.key,
    required this.onPressed,
    this.tooltip = '読み上げ',
  });

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: tooltip,
        iconSize: 32,
        constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
        icon: const Icon(Icons.volume_up),
      );
}

/// 片手・ながら学習モードの画面の骨組み。問題文は上の領域（長ければスクロール）、
/// 選択肢のボタンは画面の下に寄せて並べる（親指が届く範囲）。
class HandsFreeQuestionLayout extends StatelessWidget {
  const HandsFreeQuestionLayout({
    super.key,
    required this.question,
    required this.choices,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    this.choiceSpacing = 12,
  });

  /// 問題文など（上の領域）。
  final Widget question;

  /// 選択肢のボタン（下の領域）。通常は [HandsFreeChoiceTile] を並べる。
  final List<Widget> choices;

  /// 問題文の下に出す補助（読み上げボタンなど）。
  final Widget? trailing;

  final EdgeInsets padding;
  final double choiceSpacing;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  question,
                  if (trailing != null) ...[
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: trailing),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, padding.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < choices.length; i++) ...[
                    if (i > 0) SizedBox(height: choiceSpacing),
                    choices[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      );
}
