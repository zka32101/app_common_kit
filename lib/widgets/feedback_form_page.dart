import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feedback_limits.dart';
import '../models/feedback_model.dart';
import '../diagnostics/diagnostics.dart';
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

  /// 渡すと「診断情報を添える」のチェックを出す（既定でオン）。送る内容は、画面で確認できる。
  /// `DiagnosticsCollector(...).collect` を渡す。
  final String Function()? collectDiagnostics;

  const FeedbackFormPage({
    super.key,
    required this.appName,
    this.appVersion = '',
    this.userId,
    this.strings,
    this.collectDiagnostics,
  });

  @override
  ConsumerState<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends ConsumerState<FeedbackFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  FeedbackType _type = FeedbackType.bug;
  bool _attachDiagnostics = true;

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
          diagnostics: widget.collectDiagnostics != null && _attachDiagnostics
              ? widget.collectDiagnostics!()
              : null,
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
            if (widget.collectDiagnostics != null) ...[
              const SizedBox(height: 12),
              _DiagnosticsTile(
                strings: DiagnosticsStrings.forCode(strings.languageCode),
                value: _attachDiagnostics,
                enabled: !isSubmitting,
                onChanged: (v) => setState(() => _attachDiagnostics = v),
                collect: widget.collectDiagnostics!,
              ),
            ],
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

/// 「診断情報を添える」のチェックと、送る内容を見るボタン。
class _DiagnosticsTile extends StatelessWidget {
  const _DiagnosticsTile({
    required this.strings,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.collect,
  });

  final DiagnosticsStrings strings;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final String Function() collect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: value,
          onChanged: enabled ? (v) => onChanged(v ?? false) : null,
          title: Text(strings.attach),
          subtitle: Text(strings.attachHint),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(strings.preview),
                content: SingleChildScrollView(child: SelectableText(collect())),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.close))],
              ),
            ),
            child: Text(strings.preview),
          ),
        ),
      ],
    );
  }
}
