import 'package:flutter/material.dart';

/// 選択肢の状態。色だけに頼らず、✓／✕のアイコンと文言も出す。
enum ChoiceState {
  /// まだ選ばれていない
  idle,

  /// 選択中（回答前）
  selected,

  /// 正解（回答後）
  correct,

  /// 不正解（回答後に選んだ誤り）
  incorrect,
}

/// 問題の選択肢1つ。タップ領域は 44pt 以上。
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final success = dark ? const Color(0xFF5BD17F) : const Color(0xFF1E8E3E);

    final Color border;
    final Color? bg;
    final IconData? icon;
    final Color? iconColor;
    final String? mark;
    switch (state) {
      case ChoiceState.idle:
        border = theme.dividerColor;
        bg = null;
        icon = null;
        iconColor = null;
        mark = null;
      case ChoiceState.selected:
        border = scheme.primary;
        bg = scheme.primary.withValues(alpha: 0.10);
        icon = Icons.radio_button_checked;
        iconColor = scheme.primary;
        mark = null;
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
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: state == ChoiceState.idle ? 1 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleSmall),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text, style: theme.textTheme.bodyMedium),
                        if (mark != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              mark,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: iconColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, color: iconColor),
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
