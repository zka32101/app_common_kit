import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feedback_model.dart';
import '../providers/feedback_provider.dart';

/// 全アプリ共通の「バグ報告・改善要望」フォーム画面。
///
/// 実際の送信処理は各アプリの main.dart 等で
/// `ref.read(feedbackProvider.notifier).setSubmitHandler(...)` により
/// あらかじめ登録しておく（Firestore書き込み等はアプリ側が実装する）。
///
/// app_common_kit は特定のテーマ・認証手段に依存しないため、見た目は
/// `Theme.of(context)` に従い、userId が必要な場合は呼び出し側から渡す。
///
/// 使い方:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => const FeedbackFormPage(appName: 'kokugo-kore')),
/// );
/// ```
class FeedbackFormPage extends ConsumerStatefulWidget {
  final String appName;
  final String appVersion;
  final String? userId;

  const FeedbackFormPage({
    super.key,
    required this.appName,
    this.appVersion = '',
    this.userId,
  });

  @override
  ConsumerState<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends ConsumerState<FeedbackFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  FeedbackType _type = FeedbackType.bug;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(feedbackProvider.notifier).submitFeedback(
          type: _type,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          appName: widget.appName,
          appVersion: widget.appVersion,
          userId: widget.userId,
        );

    if (!mounted) return;
    final result = ref.read(feedbackProvider);

    if (result.status == FeedbackSubmitStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('送信しました。ありがとうございます！')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('送信に失敗しました。時間をおいて再度お試しください。')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(feedbackProvider);
    final isSubmitting = submitState.status == FeedbackSubmitStatus.submitting;
    final labelStyle = Theme.of(context)
        .textTheme
        .labelLarge
        ?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(title: const Text('ご意見・不具合報告')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('種別', style: labelStyle),
            const SizedBox(height: 8),
            SegmentedButton<FeedbackType>(
              segments: const [
                ButtonSegment(value: FeedbackType.bug, label: Text('不具合報告')),
                ButtonSegment(value: FeedbackType.feature, label: Text('改善要望')),
                ButtonSegment(value: FeedbackType.other, label: Text('その他')),
              ],
              selected: {_type},
              onSelectionChanged: isSubmitting
                  ? null
                  : (selection) => setState(() => _type = selection.first),
            ),
            const SizedBox(height: 20),
            Text('タイトル', style: labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              enabled: !isSubmitting,
              decoration: const InputDecoration(
                hintText: '例：〇〇画面でボタンが反応しない',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'タイトルを入力してください' : null,
            ),
            const SizedBox(height: 20),
            Text('詳細', style: labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              enabled: !isSubmitting,
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'できるだけ詳しく状況を教えてください',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? '詳細を入力してください' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('送信する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
