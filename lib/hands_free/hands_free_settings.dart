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
    this.thinkSeconds = defaultThinkSeconds,
    this.betweenSeconds = defaultBetweenSeconds,
    this.autoAdvance = true,
  });

  /// 片手・ながら学習モード（大きなボタン・下部配置）を使うか。
  final bool enabled;

  /// 問題文と選択肢を自動で読み上げるか（モードが有効のとき）。
  final bool speakQuestion;

  /// 解説を自動で読み上げるか（モードが有効のとき）。
  final bool speakExplanation;

  /// 読み上げの速さ。0.5〜1.5 に収める。
  final double speechRate;

  /// ながらセッション: 問題を読んだあと、答えを読むまでの「考える間」（秒）。
  final int thinkSeconds;

  /// ながらセッション: 答えを読んだあと、次の問題までの間（秒）。
  final int betweenSeconds;

  /// ながらセッション: 次の問題へ自動で進むか。false なら「スキップ」で進める。
  final bool autoAdvance;

  static const defaultThinkSeconds = 5;
  static const defaultBetweenSeconds = 2;
  static const minThinkSeconds = 1;
  static const maxThinkSeconds = 30;
  static const minBetweenSeconds = 0;
  static const maxBetweenSeconds = 10;

  /// 設定画面で選ばせる「考える間」の候補。
  static const thinkSecondsOptions = [3, 5, 8, 12];

  /// 設定画面で選ばせる「次の問題までの間」の候補。
  static const betweenSecondsOptions = [1, 2, 3, 5];

  static const minSpeechRate = 0.5;
  static const maxSpeechRate = 1.5;

  HandsFreeSettings copyWith({
    bool? enabled,
    bool? speakQuestion,
    bool? speakExplanation,
    double? speechRate,
    int? thinkSeconds,
    int? betweenSeconds,
    bool? autoAdvance,
  }) =>
      HandsFreeSettings(
        enabled: enabled ?? this.enabled,
        speakQuestion: speakQuestion ?? this.speakQuestion,
        speakExplanation: speakExplanation ?? this.speakExplanation,
        speechRate: _clampRate(speechRate ?? this.speechRate),
        thinkSeconds: _clampInt(thinkSeconds ?? this.thinkSeconds, minThinkSeconds, maxThinkSeconds),
        betweenSeconds:
            _clampInt(betweenSeconds ?? this.betweenSeconds, minBetweenSeconds, maxBetweenSeconds),
        autoAdvance: autoAdvance ?? this.autoAdvance,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'speakQuestion': speakQuestion,
        'speakExplanation': speakExplanation,
        'speechRate': speechRate,
        'thinkSeconds': thinkSeconds,
        'betweenSeconds': betweenSeconds,
        'autoAdvance': autoAdvance,
      };

  /// 壊れた・欠けた保存データでも、読めた項目だけを使い、残りは既定値にする。
  factory HandsFreeSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HandsFreeSettings();
    bool flag(String key, bool fallback) => json[key] is bool ? json[key] as bool : fallback;
    int seconds(String key, int fallback, int min, int max) =>
        json[key] is num ? _clampInt((json[key] as num).round(), min, max) : fallback;
    final rate = json['speechRate'];
    return HandsFreeSettings(
      enabled: flag('enabled', false),
      speakQuestion: flag('speakQuestion', true),
      speakExplanation: flag('speakExplanation', true),
      speechRate: rate is num ? _clampRate(rate.toDouble()) : 1.0,
      thinkSeconds: seconds('thinkSeconds', defaultThinkSeconds, minThinkSeconds, maxThinkSeconds),
      betweenSeconds:
          seconds('betweenSeconds', defaultBetweenSeconds, minBetweenSeconds, maxBetweenSeconds),
      autoAdvance: flag('autoAdvance', true),
    );
  }

  static int _clampInt(int v, int min, int max) => v.clamp(min, max).toInt();

  static double _clampRate(double v) => v.clamp(minSpeechRate, maxSpeechRate).toDouble();

  @override
  bool operator ==(Object other) =>
      other is HandsFreeSettings &&
      other.enabled == enabled &&
      other.speakQuestion == speakQuestion &&
      other.speakExplanation == speakExplanation &&
      other.speechRate == speechRate &&
      other.thinkSeconds == thinkSeconds &&
      other.betweenSeconds == betweenSeconds &&
      other.autoAdvance == autoAdvance;

  @override
  int get hashCode => Object.hash(
        enabled,
        speakQuestion,
        speakExplanation,
        speechRate,
        thinkSeconds,
        betweenSeconds,
        autoAdvance,
      );
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
  SharedPreferencesHandsFreeStore(
    this.appId, {
    this.keyPrefix = 'ukalab_hands_free_',
  });

  final String appId;

  /// 保存キーの前置き。既定は従来のまま（変えると保存済みの設定が読めなくなる）。
  final String keyPrefix;

  String get _key => '$keyPrefix$appId';

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
  Future<void> setThinkSeconds(int value) => update(state.copyWith(thinkSeconds: value));
  Future<void> setBetweenSeconds(int value) => update(state.copyWith(betweenSeconds: value));
  Future<void> setAutoAdvance(bool value) => update(state.copyWith(autoAdvance: value));
}

final handsFreeProvider =
    NotifierProvider<HandsFreeNotifier, HandsFreeSettings>(HandsFreeNotifier.new);
