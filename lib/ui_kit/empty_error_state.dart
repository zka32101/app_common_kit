import 'package:flutter/material.dart';

import 'kit_strings.dart';

/// 空状態。前向きな文言で、次にできることを示す。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) =>
      _StateBody(icon: icon, message: message, actionLabel: actionLabel, onAction: onAction);
}

/// エラー表示。責めず、やり直しの手段を示す。
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message,
    this.retryLabel,
    this.onRetry,
  });

  /// null なら [KitStrings] の既定文言。
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = KitStrings.of(context);
    return _StateBody(
      icon: Icons.error_outline,
      message: message ?? strings.errorMessage,
      actionLabel: onRetry == null ? null : (retryLabel ?? strings.retry),
      onAction: onRetry,
    );
  }
}

class _StateBody extends StatelessWidget {
  const _StateBody({required this.icon, required this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
