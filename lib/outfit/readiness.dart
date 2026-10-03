import '../mascot/mascot_logic.dart';

/// 「準備完了」の判定（暫定）。
///
/// 設計書（推し×資格連動要素 v0.1）では、準備完了は「最短ルートの目標達成」で解放する。
/// 最短ルートプランナーが完成するまでの暫定として、次の**両方**を満たしたら準備完了とする。
///
/// - 習得度が最高段階の境目（既定 0.8）以上
/// - 模擬試験で合格点を1回以上超えた
///
/// 数値は差し替えられる（Remote Config から作る想定）。責める文言は出さない。
class ReadinessRule {
  const ReadinessRule({this.minMastery = 0.8, this.requireMockPass = true});

  final double minMastery;
  final bool requireMockPass;

  static const ReadinessRule standard = ReadinessRule();

  bool isReady({required MasteryInput mastery, required bool mockPassed, MasteryModel model = MasteryModel.standard}) {
    if (requireMockPass && !mockPassed) return false;
    return model.mastery(mastery) >= minMastery;
  }
}
