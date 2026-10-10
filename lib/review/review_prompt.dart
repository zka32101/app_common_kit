import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'review_backend.dart';

/// レビューを頼む条件。既定は控えめ（頼みすぎない）。
class ReviewPromptRules {
  const ReviewPromptRules({
    this.minDaysSinceFirstLaunch = 7,
    this.minPositiveMoments = 3,
    this.minDaysBetweenAsks = 120,
    this.maxAsksTotal = 3,
    this.declinedCooldownDays = 90,
  });

  /// 初回起動から、この日数が過ぎるまでは頼まない。
  final int minDaysSinceFirstLaunch;

  /// 良い体験（合格・自己ベスト・連続学習など）を、これだけ記録するまでは頼まない。
  final int minPositiveMoments;

  /// 前回頼んでから、この日数が過ぎるまでは頼まない。
  final int minDaysBetweenAsks;

  /// 頼む回数の上限（生涯）。
  final int maxAsksTotal;

  /// 「楽しんでいない」と答えた後、この日数は頼まない。
  final int declinedCooldownDays;

  static const standard = ReviewPromptRules();
}

/// 頼んでよいかの判定結果。[ask] 以外は、頼まない理由。
enum ReviewDecision {
  ask,
  tooEarly,
  notEnoughMoments,
  alreadyAskedThisSession,
  tooSoonSinceLastAsk,
  limitReached,
  declinedRecently,
  unavailable,
}

/// 保存する状態。
class ReviewState {
  const ReviewState({
    this.firstLaunch,
    this.positiveMoments = 0,
    this.askCount = 0,
    this.lastAskedAt,
    this.declinedAt,
  });

  final DateTime? firstLaunch;
  final int positiveMoments;
  final int askCount;
  final DateTime? lastAskedAt;
  final DateTime? declinedAt;

  ReviewState copyWith({
    DateTime? firstLaunch,
    int? positiveMoments,
    int? askCount,
    DateTime? lastAskedAt,
    DateTime? declinedAt,
  }) =>
      ReviewState(
        firstLaunch: firstLaunch ?? this.firstLaunch,
        positiveMoments: positiveMoments ?? this.positiveMoments,
        askCount: askCount ?? this.askCount,
        lastAskedAt: lastAskedAt ?? this.lastAskedAt,
        declinedAt: declinedAt ?? this.declinedAt,
      );

  Map<String, dynamic> toJson() => {
        if (firstLaunch != null) 'firstLaunch': firstLaunch!.toIso8601String(),
        'positiveMoments': positiveMoments,
        'askCount': askCount,
        if (lastAskedAt != null) 'lastAskedAt': lastAskedAt!.toIso8601String(),
        if (declinedAt != null) 'declinedAt': declinedAt!.toIso8601String(),
      };

  /// 壊れた保存データでも、読めた項目だけを使う。
  factory ReviewState.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ReviewState();
    DateTime? d(Object? v) => v is String ? DateTime.tryParse(v) : null;
    int n(Object? v) => v is int && v >= 0 ? v : 0;
    return ReviewState(
      firstLaunch: d(j['firstLaunch']),
      positiveMoments: n(j['positiveMoments']),
      askCount: n(j['askCount']),
      lastAskedAt: d(j['lastAskedAt']),
      declinedAt: d(j['declinedAt']),
    );
  }
}

abstract class ReviewStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> json);
}

class InMemoryReviewStore implements ReviewStore {
  Map<String, dynamic>? _m;

  @override
  Future<Map<String, dynamic>?> read() async => _m;

  @override
  Future<void> write(Map<String, dynamic> json) async => _m = json;
}

/// 端末内の保存。アプリごとに [appId] でキーを分ける。
class SharedPreferencesReviewStore implements ReviewStore {
  SharedPreferencesReviewStore(this.appId);

  final String appId;

  String get _key => 'app_common_kit_review_$appId';

  @override
  Future<Map<String, dynamic>?> read() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return null;
    try {
      final v = jsonDecode(s);
      return v is Map ? Map<String, dynamic>.from(v) : null;
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

/// アプリ内レビューを頼むタイミングの制御。
///
/// - 良い体験の直後（合格・自己ベスト・連続学習など）に [recordPositiveMoment] で記録する
/// - 頼んでよい場面で [maybeRequest]（または確認ダイアログの `showReviewPrePrompt`）を呼ぶ
/// - 初回起動から日が浅い・良い体験が少ない・前回から日が浅い・上限に達した・断られた直後・
///   同じ起動中にもう頼んだ、のどれかなら頼まない
/// - 頼んだら、良い体験の数を0に戻す（次は、また新しく溜めてから）
///
/// 頼む前に「楽しんでいますか？」と聞き、「いいえ」ならレビューではなくフィードバックへ案内するのが定石
/// （`showReviewPrePrompt`）。
class ReviewPromptService {
  ReviewPromptService({
    required this.store,
    required this.backend,
    this.rules = ReviewPromptRules.standard,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final ReviewStore store;
  final ReviewBackend backend;
  final ReviewPromptRules rules;
  final DateTime Function() _clock;

  ReviewState _state = const ReviewState();
  bool _askedThisSession = false;

  ReviewState get state => _state;

  /// 起動時に呼ぶ。初回起動の日付をここで記録する。
  Future<void> load() async {
    _state = ReviewState.fromJson(await store.read());
    if (_state.firstLaunch == null) {
      _state = _state.copyWith(firstLaunch: _clock());
      await _save();
    }
  }

  Future<void> _save() => store.write(_state.toJson());

  /// 良い体験を1つ記録する。
  Future<void> recordPositiveMoment() async {
    _state = _state.copyWith(positiveMoments: _state.positiveMoments + 1);
    await _save();
  }

  /// いま頼んでよいか。副作用はない。
  ReviewDecision evaluate() {
    final now = _clock();
    final declined = _state.declinedAt;
    if (declined != null && now.difference(declined).inDays < rules.declinedCooldownDays) {
      return ReviewDecision.declinedRecently;
    }
    if (_state.askCount >= rules.maxAsksTotal) return ReviewDecision.limitReached;
    final first = _state.firstLaunch;
    if (first == null || now.difference(first).inDays < rules.minDaysSinceFirstLaunch) {
      return ReviewDecision.tooEarly;
    }
    if (_state.positiveMoments < rules.minPositiveMoments) return ReviewDecision.notEnoughMoments;
    if (_askedThisSession) return ReviewDecision.alreadyAskedThisSession;
    final last = _state.lastAskedAt;
    if (last != null && now.difference(last).inDays < rules.minDaysBetweenAsks) {
      return ReviewDecision.tooSoonSinceLastAsk;
    }
    return ReviewDecision.ask;
  }

  /// 条件を満たしていれば、アプリ内のレビュー画面を出す。結果（出した／出さない理由）を返す。
  /// 失敗（プラグインの例外など）は握りつぶし、頼んだことにはしない。
  Future<ReviewDecision> maybeRequest() async {
    final decision = evaluate();
    if (decision != ReviewDecision.ask) return decision;
    try {
      if (!await backend.isAvailable()) return ReviewDecision.unavailable;
      await backend.requestReview();
    } catch (_) {
      return ReviewDecision.unavailable;
    }
    _askedThisSession = true;
    _state = _state.copyWith(
      positiveMoments: 0, // 次は、また新しく溜めてから
      askCount: _state.askCount + 1,
      lastAskedAt: _clock(),
    );
    await _save();
    return ReviewDecision.ask;
  }

  /// 「楽しんでいない」と答えられたとき。しばらく頼まない。
  Future<void> declined() async {
    _state = _state.copyWith(declinedAt: _clock());
    await _save();
  }
}

/// アプリ側で上書きして使う。
///
/// ```dart
/// ProviderScope(overrides: [
///   reviewPromptServiceProvider.overrideWithValue(ReviewPromptService(
///     store: SharedPreferencesReviewStore('boki3'),
///     backend: MyReviewBackend(), // in_app_review などで実装
///   )),
/// ])
/// ```
final reviewPromptServiceProvider = Provider<ReviewPromptService>(
  (ref) => throw UnimplementedError('reviewPromptServiceProvider を override してください'),
);
