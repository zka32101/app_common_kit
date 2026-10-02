import 'package:flutter/widgets.dart';

import '../theme/ukalab_palette.dart';

/// 成長段階（習得度で決まる。Lv1〜5）。
enum MascotStage {
  lv1,
  lv2,
  lv3,
  lv4,
  lv5;

  int get level => index + 1;
}

/// 表情。責める・落ち込む表情は作らない。
enum MascotExpression { normal, joy }

/// 試験日が近いときの装い（日程連動。無料）。
enum ExamPhase {
  /// 試験日を設定していない／まだ遠い
  none,

  /// 30日以内
  approaching,

  /// 7日以内（はちまき）
  close,

  /// 前日
  eve,

  /// 当日
  today,
}

/// 口調。セリフの文言はパックごとに管理する。
enum MascotTone { gentle, cool, cheerful, relaxed }

/// 表示サイズ（設定: 推しを小さく／非表示）。
enum MascotDisplay { normal, small, hidden }

/// 画像パックの画像を返す関数。null ならコード描画に戻す。
typedef MascotImageBuilder = ImageProvider? Function(
  MascotStage stage,
  MascotExpression expression,
);

/// キャラクターパック（データ）。ロジックは共通で、見た目とセリフの口調だけが違う。
///
/// 標準キャラ（フラスコの助手）は [CharacterPack.standard] で、コード描画のため画像不要。
/// AI 画像のパックは [imageBuilder] を渡して作る（選択時に取得する想定）。
class CharacterPack {
  const CharacterPack({
    required this.id,
    required this.name,
    required this.tone,
    this.imageBuilder,
    this.fieldAccent = const {},
    this.signature,
  });

  final String id;
  final String name;
  final MascotTone tone;

  /// 段階×表情の画像。null ならコード描画（標準キャラ）。
  final MascotImageBuilder? imageBuilder;

  /// 分野ごとの差し色。なければ分野色（テーマ）を使う。
  final Map<UkalabField, Color> fieldAccent;

  /// 配信データの署名（検証は配信を実装するときに追加）。
  final String? signature;

  bool get isBuiltIn => imageBuilder == null;

  /// 標準キャラ「フラスコの助手」（仮名「うか」）。
  static const CharacterPack standard = CharacterPack(
    id: 'standard',
    name: 'うか',
    tone: MascotTone.gentle,
  );
}
