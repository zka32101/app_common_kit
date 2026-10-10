import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui_kit/choice_tile.dart';
import '../ui_kit/hands_free.dart';
import 'hands_free_providers.dart';
import 'speech.dart';

/// 演習（選択式）の、ながら学習モードの表示。問題文は上、大きな選択肢ボタンは下に寄せる。
/// 問題が変わるたびに、設定に従って問題文と選択肢を自動で読み上げる。
class HandsFreeChoiceBody extends ConsumerStatefulWidget {
  const HandsFreeChoiceBody({
    super.key,
    required this.qid,
    required this.prompt,
    required this.choices,
    required this.index,
    required this.total,
    required this.onSelect,
  });

  /// 問題が変わったかの判定に使う（同じ問題の再描画では読み直さない）。
  final String qid;
  final String prompt;

  /// 画面に出す順に並べた選択肢の文。
  final List<String> choices;
  final int index;
  final int total;

  /// 選択肢をタップしたとき。表示順の位置（0始まり）。
  final void Function(int position) onSelect;

  @override
  ConsumerState<HandsFreeChoiceBody> createState() => _HandsFreeChoiceBodyState();
}

class _HandsFreeChoiceBodyState extends ConsumerState<HandsFreeChoiceBody> {
  late final HandsFreeSpeaker _speaker = ref.read(handsFreeSpeakerProvider);

  @override
  void initState() {
    super.initState();
    _autoRead();
  }

  @override
  void didUpdateWidget(covariant HandsFreeChoiceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qid != widget.qid) _autoRead();
  }

  @override
  void dispose() {
    // 画面を離れたら読み上げを止める。
    _speaker.stop();
    super.dispose();
  }

  void _autoRead() => _speaker.readQuestion(widget.prompt, widget.choices);

  @override
  Widget build(BuildContext context) {
    return HandsFreeQuestionLayout(
      question: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '問題 ${widget.index} / ${widget.total}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          Text(widget.prompt, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      trailing: ReadAloudButton(
        onPressed: () => _speaker.speakNow(questionReadAloudText(widget.prompt, widget.choices)),
      ),
      choices: [
        for (var i = 0; i < widget.choices.length; i++)
          HandsFreeChoiceTile(
            label: String.fromCharCode(0x41 + i),
            text: widget.choices[i],
            state: ChoiceState.idle,
            onTap: () => widget.onSelect(i),
          ),
      ],
    );
  }
}
