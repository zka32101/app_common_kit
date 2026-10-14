import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui_kit/choice_tile.dart';
import '../ui_kit/hands_free.dart';
import '../ui_kit/kit_strings.dart';
import 'hands_free_providers.dart';
import 'hands_free_settings.dart';
import 'nagara_session_controller.dart';
import 'nagara_strings.dart';
import 'speech.dart';

/// ながらセッション（画面点灯中の自動進行ハンズフリー学習）の画面。
///
/// 問題と選択肢を読み、考える間を置き、正解と解説を読んで次へ進む。
/// 選択肢のタップでも答えられる（正誤を読んで次へ）。誤答は [onWrongAnswer] でアプリに返す。
/// 画面を離れると読み上げとタイマーを止める。読み上げは [speechBackendProvider]、
/// 間の長さなどは [handsFreeProvider] の設定に従う。
class NagaraSessionView extends ConsumerStatefulWidget {
  const NagaraSessionView({
    super.key,
    required this.questions,
    this.maxQuestions,
    this.onAnswered,
    this.onWrongAnswer,
    this.onUnanswered,
    this.onFinished,
    this.onClose,
  });

  final List<NagaraQuestion> questions;

  /// ひと続きの上限問数（子ども向けの休憩促し用）。null なら全問。
  final int? maxQuestions;

  /// 誤答（タップ回答）。アプリが復習キューや間違いノートに積む。
  /// タップで答えが確定したとき（正答・誤答とも。未回答・スキップでは呼ばない）。
  /// [NagaraSessionController.onAnswered] と同じ。
  final void Function(NagaraQuestion question, int chosen, bool correct)? onAnswered;

  final void Function(NagaraQuestion question, int chosen)? onWrongAnswer;

  /// 考える間のうちに答えがなかった問題。
  final void Function(NagaraQuestion question)? onUnanswered;

  /// 終わったとき。
  final void Function(NagaraSessionState summary)? onFinished;

  /// 終了後の「とじる」ボタン。null ならボタンを出さない。
  final VoidCallback? onClose;

  @override
  ConsumerState<NagaraSessionView> createState() => _NagaraSessionViewState();
}

class _NagaraSessionViewState extends ConsumerState<NagaraSessionView> {
  NagaraSessionController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final c = NagaraSessionController(
      questions: widget.questions,
      backend: ref.read(speechBackendProvider),
      settings: () => ref.read(handsFreeProvider),
      strings: KitStrings.of(context).nagara,
      maxQuestions: widget.maxQuestions,
      onAnswered: (q, i, ok) => widget.onAnswered?.call(q, i, ok),
      onWrongAnswer: (q, i) => widget.onWrongAnswer?.call(q, i),
      onUnanswered: (q) => widget.onUnanswered?.call(q),
      onFinished: (s) => widget.onFinished?.call(s),
    );
    // 画面を組み立てている最中に setState しないよう、始めてから購読する。
    c.start();
    c.addListener(() {
      if (mounted) setState(() {});
    });
    _controller = c;
  }

  @override
  void dispose() {
    // 画面を離れたら読み上げもタイマーも必ず止める。
    _controller?.dispose();
    super.dispose();
  }

  String _phaseLabel(NagaraSessionState st, NagaraStrings t) {
    switch (st.phase) {
      case NagaraPhase.readingQuestion:
        return t.phaseReadingQuestion;
      case NagaraPhase.waitingAnswer:
        return t.phaseWaitingAnswer;
      case NagaraPhase.readingAnswer:
        return t.phaseReadingAnswer;
      case NagaraPhase.pausedBetween:
        return t.phasePausedBetween;
      case NagaraPhase.paused:
        return t.phasePaused;
      case NagaraPhase.finished:
        return t.phaseFinished;
      case NagaraPhase.idle:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller!;
    final st = c.state;
    final q = c.currentQuestion;
    final strings = KitStrings.of(context);
    final t = strings.nagara;
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (st.isFinished || q == null) {
      return _FinishedPanel(state: st, onClose: widget.onClose);
    }

    final answerable =
        st.phase == NagaraPhase.readingQuestion || st.phase == NagaraPhase.waitingAnswer;

    ChoiceState tileState(int i) {
      if (st.result == null) return ChoiceState.idle;
      if (i == q.correctIndex) return ChoiceState.correct;
      if (i == st.chosen) return ChoiceState.incorrect;
      return ChoiceState.idle;
    }

    final explanation = q.explanation;
    final showExplanation = st.result != null && explanation != null && explanation.trim().isNotEmpty;

    // 文字が非常に大きいときは、固定の操作ボタンだけで画面が埋まってしまうので、
    // 画面全体（見出し・問題・ボタン）をひとつにしてスクロールさせる。
    final scrollAll = MediaQuery.textScalerOf(context).scale(14) / 14 > 2.0;

    final page = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                label: '${t.positionLabel(st.index + 1, st.total)}${strings.sentenceSeparator}'
                    '${t.remainingLabel(st.remaining)}',
                excludeSemantics: true,
                child: Row(
                  children: [
                    // 文字を大きくしても 2 つとも折り返して全部見えるようにする
                    Flexible(child: Text(t.positionLabel(st.index + 1, st.total), style: theme.textTheme.titleMedium)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        t.remainingLabel(st.remaining),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: st.total == 0 ? 0 : st.completed / st.total),
            ],
          ),
        ),
        _middle(
          scrollAll: scrollAll,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  liveRegion: true,
                  child: AnimatedSwitcher(
                    duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(st.phase),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_phaseIcon(st.phase), color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _phaseLabel(st, t),
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (st.speechFailed) ...[
                  const SizedBox(height: 8),
                  Text(t.speechUnavailable, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 16),
                Text(q.prompt, style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                for (var i = 0; i < q.choices.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  HandsFreeChoiceTile(
                    label: readAloudChoiceLabel(i),
                    text: q.choices[i],
                    state: tileState(i),
                    incorrectText: t.chosenLabel,
                    onTap: answerable ? () => c.answer(i) : null,
                  ),
                ],
                if (answerable) ...[
                  const SizedBox(height: 12),
                  Text(t.tapHint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                ],
                if (showExplanation) ...[
                  const SizedBox(height: 16),
                  Text(explanation, style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: 16),
              ],
            ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: st.isPaused
                      ? _ControlButton(icon: Icons.play_arrow, label: t.resume, onPressed: c.resume)
                      : _ControlButton(icon: Icons.pause, label: t.pause, onPressed: c.pause),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ControlButton(
                    icon: Icons.skip_next,
                    label: t.skip,
                    onPressed: st.isPaused ? null : c.skip,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _ControlButton(icon: Icons.stop, label: t.stop, onPressed: c.stop)),
              ],
            ),
          ),
        ),
      ],
    );
    return scrollAll ? SingleChildScrollView(child: page) : page;
  }

  static Widget _middle({required bool scrollAll, required Widget child}) {
    const pad = EdgeInsets.symmetric(horizontal: 16);
    if (scrollAll) return Padding(padding: pad, child: child);
    return Expanded(child: SingleChildScrollView(padding: pad, child: child));
  }

  static IconData _phaseIcon(NagaraPhase p) {
    switch (p) {
      case NagaraPhase.readingQuestion:
      case NagaraPhase.readingAnswer:
        return Icons.volume_up;
      case NagaraPhase.waitingAnswer:
        return Icons.hourglass_empty;
      case NagaraPhase.pausedBetween:
        return Icons.coffee;
      case NagaraPhase.paused:
        return Icons.pause_circle;
      case NagaraPhase.finished:
      case NagaraPhase.idle:
        return Icons.check_circle;
    }
  }
}

/// 一時停止・スキップ・終了などの大きなボタン（高さ・幅とも 72pt 以上）。
class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.label, required this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  static const double minSize = 72;

  @override
  Widget build(BuildContext context) => FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(minSize, minSize),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 4),
            // 「…」で隠さず、狭いときは折り返して全文を見せる
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      );
}

class _FinishedPanel extends StatelessWidget {
  const _FinishedPanel({required this.state, required this.onClose});

  final NagaraSessionState state;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final strings = KitStrings.of(context);
    final t = strings.nagara;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(t.phaseFinished, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 16),
            if (state.completed > 0)
              Text(
                t.finishedSummary(state.correctCount, state.completed),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            if (state.finishReason == NagaraFinishReason.limitReached) ...[
              const SizedBox(height: 16),
              Text(t.restSuggestion, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            ],
            if (onClose != null) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(minimumSize: const Size(72, 72)),
                child: Text(t.close),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
