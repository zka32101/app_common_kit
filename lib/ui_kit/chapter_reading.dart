import 'package:flutter/material.dart';

import 'lab_strings.dart';
import 'term_card.dart' show RelatedTermRef, RelatedQuestionRef;

/// 章ごとの解説読み物（教科書的なまとめページ）の1節（見出し＋本文）。
class ReadingSectionView {
  const ReadingSectionView({required this.heading, required this.body});

  final String heading;
  final String body;
}

/// 章ごとの解説読み物（決定「章ごとの解説読み物（教科書的なまとめページ）」）。
///
/// 用語の暗記だけでなく、章の学習項目を体系的に読める記事を表示する。
/// 節（見出し＋本文）を順に表示し、末尾に関連用語・関連問題を出す。
class ChapterReadingWidget extends StatelessWidget {
  const ChapterReadingWidget({
    super.key,
    required this.title,
    required this.sections,
    this.relatedTerms = const [],
    this.relatedQuestions = const [],
    this.onRelatedTermTap,
    this.onRelatedQuestionTap,
  });

  final String title;
  final List<ReadingSectionView> sections;
  final List<RelatedTermRef> relatedTerms;
  final List<RelatedQuestionRef> relatedQuestions;
  final ValueChanged<String>? onRelatedTermTap;
  final ValueChanged<String>? onRelatedQuestionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          for (final s in sections) ...[
            const SizedBox(height: 20),
            Text(
              s.heading,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(s.body, style: theme.textTheme.bodyLarge),
          ],
          if (relatedTerms.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(LabStrings.of(context).termRelatedTerms, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in relatedTerms)
                  ActionChip(
                    label: Text(r.label),
                    onPressed: onRelatedTermTap == null
                        ? null
                        : () => onRelatedTermTap!(r.termId),
                  ),
              ],
            ),
          ],
          if (relatedQuestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(LabStrings.of(context).termRelatedQuestions, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            for (final r in relatedQuestions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onRelatedQuestionTap == null
                        ? null
                        : () => onRelatedQuestionTap!(r.questionId),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(r.label),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
