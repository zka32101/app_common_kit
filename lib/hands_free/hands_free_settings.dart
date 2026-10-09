import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 片手・ながら学習モードの設定（通勤中などの片手操作・耳で聞く学習）。
///
/// [enabled] が true のとき、画面は大きなボタンを下部に並べる（[HandsFreeQuestionLayout]）。
/// 読み上げは端末標準の音声合成を使う（[SpeechBackend] をアプリが実装して渡す）。
class HandsFreeSettings {
  const HandsFreeSettings({
    this.enabled = false,
    this.speakQuestion = true,
    this.speakExplanation = true,
    this.speechRate = 1.0,
  });

  /// 片手・ながら学習モード（大きなボタン・下部配置）を使うか。
  final bool enabled;

  /// 問題文と選択肢を自動で読み上げるか（モードが有効のとき）。
  final bool speakQuestion;

  /// 解説を自動で読み上げるか（モードが有効のとき）。
  final bool speakExplanation;

  /// 読み上げの速さ。0.5〜1.5 に収める。
  final double speechRate;

  static const minSpeechRate = 0.5;
  static const maxSpeechRate = 1.5;

  HandsFreeSettings copyWith({
    bool? enabled,
    bool? speakQuestion,
    bool? speakExplanation,
    double? speechRate,
  }) =>
      HandsFreeSettings(
        enabled: enabled ?? this.enabled,
        speakQuestion: speakQuestion ?? this.speakQuestion,
        speakExplanation: speakExplanation ?? this.speakExplanation,
        speechRate: _clampRate(speechRate ?? this.speechRate),
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'speakQuestion': speakQuestion,
        'speakExplanation': speakExplanation,
        'speechRate': speechRate,
      };

  /// 壊れた・欠けた保存データでも、読めた項目だけを使い、残りは既定値にする。
  factory HandsFreeSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HandsFreeSettings();
    bool flag(String key, bool fallback) => json[key] is bool ? json[key] as bool : fallback;
    final rate = json['speechRate'];
    return HandsFreeSettings(
      enabled: flag('enabled', false),
      speakQuestion: flag('speakQuestion', true),
      speakExplanation: flag('speakExplanation', true),
      speechRate: rate is num ? _clampRate(rate.toDouble()) : 1.0,
    );
  }

  static double _clampRate(double v) => v.clamp(minSpeechRate, maxSpeechRate).toDouble();

  @override
  bool operator ==(Object other) =>
      other is HandsFreeSettings &&
      other.enabled == enabled &&
      other.speakQuestion == speakQuestion &&
      other.speakExplanation == speakExplanation &&
      other.speechRate == speechRate;

  @override
  int get hashCode => Object.hash(enabled, speakQuestion, speakExplanation, speechRate);
}

/// 設定の保存先。
abstract class HandsFreeStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> json);
}

class InMemoryHandsFreeStore implements HandsFreeStore {
  Map<String, dynamic>? _m;

  @override
  Future<Map<String, dynamic>?> read() async => _m;

  @override
  Future<void> write(Map<String, dynamic> json) async => _m = json;
}

class SharedPreferencesHandsFreeStore implements HandsFreeStore {
  SharedPreferencesHandsFreeStore(this.appId);

  final String appId;

  String get _key => 'ukalab_hands_free_$appId';

  @override
  Future<Map<String, dynamic>?> read() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Map<String, dynamic> json) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(json));
  }
}

/// アプリ側で上書きして使う。
///
/// ```dart
/// ProviderScope(overrides: [
///   handsFreeStoreProvider.overrideWithValue(SharedPreferencesHandsFreeStore('g_kentei')),
/// ])
/// ```
final handsFreeStoreProvider = Provider<HandsFreeStore>(
  (ref) => throw UnimplementedError('handsFreeStoreProvider を override してください'),
);

class HandsFreeNotifier extends Notifier<HandsFreeSettings> {
  HandsFreeStore get _store => ref.read(handsFreeStoreProvider);

  @override
  HandsFreeSettings build() => const HandsFreeSettings();

  /// 起動時に保存済みの設定を読み込む。
  Future<void> load() async {
    state = HandsFreeSettings.fromJson(await _store.read());
  }

  Future<void> update(HandsFreeSettings settings) async {
    state = settings;
    await _store.write(settings.toJson());
  }

  Future<void> setEnabled(bool value) => update(state.copyWith(enabled: value));
  Future<void> setSpeakQuestion(bool value) => update(state.copyWith(speakQuestion: value));
  Future<void> setSpeakExplanation(bool value) => update(state.copyWith(speakExplanation: value));
  Future<void> setSpeechRate(double value) => update(state.copyWith(speechRate: value));
}

final handsFreeProvider =
    NotifierProvider<HandsFreeNotifier, HandsFreeSettings>(HandsFreeNotifier.new);
