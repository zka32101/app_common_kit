import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feedback_limits.dart';
import '../models/feedback_model.dart';
import '../providers/feedback_provider.dart';
import '../ui_kit/kit_strings.dart';

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

  /// 文言。null なら最も近い `KitStringsScope`（無ければ日本語）。
  /// 画面は Navigator の上に積まれるため、Scope は `MaterialApp.builder` など Navigator より上に置くか、ここで渡す。
  final KitStrings? strings;

  const FeedbackFormPage({
    super.key,
    required this.appName,
    this.appVersion = '',
    this.userId,
    this.strings,
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

    await ref
        .read(feedbackProvider.notifier)
        .submitFeedback(
          type: _type,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          appName: widget.appName,
          appVersion: widget.appVersion,
          userId: widget.userId,
        );

    if (!mounted) return;
    final strings = widget.strings ?? KitStrings.of(context);
    final result = ref.read(feedbackProvider);

    if (result.status == FeedbackSubmitStatus.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.feedbackSent)));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.feedbackFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings ?? KitStrings.of(context);
    final submitState = ref.watch(feedbackProvider);
    final isSubmitting = submitState.status == FeedbackSubmitStatus.submitting;
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(title: Text(strings.feedbackTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(strings.feedbackType, style: labelStyle),
            const SizedBox(height: 8),
            SegmentedButton<FeedbackType>(
              segments: [
                ButtonSegment(
                  value: FeedbackType.bug,
                  label: Text(strings.feedbackBug),
                ),
                ButtonSegment(
                  value: FeedbackType.feature,
                  label: Text(strings.feedbackFeature),
                ),
                ButtonSegment(
                  value: FeedbackType.other,
                  label: Text(strings.feedbackOther),
                ),
              ],
              selected: {_type},
              onSelectionChanged: isSubmitting
                  ? null
                  : (selection) => setState(() => _type = selection.first),
            ),
            const SizedBox(height: 20),
            Text(strings.feedbackSubject, style: labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              enabled: !isSubmitting,
              decoration: InputDecoration(
                hintText: strings.feedbackSubjectHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  FeedbackLimits.standard.validateTitle(v, KitStrings.of(context)),
            ),
            const SizedBox(height: 20),
            Text(strings.feedbackDetail, style: labelStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              enabled: !isSubmitting,
              minLines: 5,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: strings.feedbackDetailHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) => FeedbackLimits.standard
                  .validateDescription(v, KitStrings.of(context)),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(strings.feedbackSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
