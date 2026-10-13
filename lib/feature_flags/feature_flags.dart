import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// リモートからフラグを取る窓口。Firebase Remote Config などはアプリ側で実装して渡す（キットは依存しない）。
abstract class FeatureFlagBackend {
  /// キー → 値（bool / int / double / String）。失敗したら例外を投げてよい。
  Future<Map<String, Object?>> fetch();
}

/// テスト・プレビュー用。
class FakeFeatureFlagBackend implements FeatureFlagBackend {
  FakeFeatureFlagBackend([this.values = const {}, this.error]);

  Map<String, Object?> values;
  Object? error;

  @override
  Future<Map<String, Object?>> fetch() async {
    if (error != null) throw error!;
    return values;
  }
}

/// 前回取得した値の保存先。
abstract class FeatureFlagCache {
  Future<Map<String, Object?>> load();
  Future<void> save(Map<String, Object?> values);
  Future<void> clear();
}

class SharedPreferencesFeatureFlagCache implements FeatureFlagCache {
  SharedPreferencesFeatureFlagCache(
    this.appId, {
    this.keyPrefix = 'kit_feature_flags_',
  });

  final String appId;
  final String keyPrefix;

  String get _key => '$keyPrefix$appId';

  @override
  Future<Map<String, Object?>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return {};
    try {
      final v = jsonDecode(raw);
      return v is Map<String, dynamic> ? Map<String, Object?>.of(v) : {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> save(Map<String, Object?> values) async =>
      (await SharedPreferences.getInstance()).setString(
        _key,
        jsonEncode(values),
      );

  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

/// テスト・プレビュー用。
class InMemoryFeatureFlagCache implements FeatureFlagCache {
  Map<String, Object?> _data = {};

  @override
  Future<Map<String, Object?>> load() async => Map.of(_data);

  @override
  Future<void> save(Map<String, Object?> values) async =>
      _data = Map.of(values);

  @override
  Future<void> clear() async => _data = {};
}

/// 機能フラグ。段階リリース・緊急停止・実験の切り替えに使う。
///
/// - [defaults] に載せたキーだけが有効。値の型は既定値の型に合わせる（型が違う値は無視して既定値）
/// - [load] は、保存済みの前回値を先に反映し、取得できたら上書きして保存する。取得に失敗しても例外は出さず、前回値か既定値で動く
/// - 読み取りは同期。[load] 前は既定値を返す
class FeatureFlags {
  FeatureFlags({
    required Map<String, Object> defaults,
    this.backend,
    FeatureFlagCache? cache,
    this.timeout = const Duration(seconds: 5),
  }) : _defaults = Map.unmodifiable(defaults),
       _cache = cache;

  final Map<String, Object> _defaults;
  final FeatureFlagBackend? backend;
  final FeatureFlagCache? _cache;
  final Duration timeout;

  Map<String, Object?> _remote = {};
  final Map<String, Object> _overrides = {};

  /// 前回値を読み、続けてリモート値を取りに行く。取得に成功したら true。
  Future<bool> load() async {
    if (_cache != null) {
      try {
        _remote = await _cache.load();
      } catch (_) {}
    }
    final b = backend;
    if (b == null) return false;
    try {
      final fetched = await b.fetch().timeout(timeout);
      _remote = Map.of(fetched);
      try {
        await _cache?.save(_remote);
      } catch (_) {}
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 開発・テスト用に値を固定する。リモート値より優先。
  void override(String key, Object value) => _overrides[key] = value;

  void clearOverrides() => _overrides.clear();

  T _get<T extends Object>(String key) {
    final def = _defaults[key];
    if (def is! T) {
      throw ArgumentError('フラグ "$key" は ${T.toString()} 型の既定値が登録されていません');
    }
    final o = _overrides[key];
    if (o is T) return o;
    final r = _remote[key];
    if (r is T) return r;
    // JSON 由来の int → double の取りこぼしを許す。
    if (T == double && r is int) return r.toDouble() as T;
    return def;
  }

  bool getBool(String key) => _get<bool>(key);
  int getInt(String key) => _get<int>(key);
  double getDouble(String key) => _get<double>(key);
  String getString(String key) => _get<String>(key);
}

/// アプリ起動時に `featureFlagsProvider.overrideWithValue(...)` で差し替える。
final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => FeatureFlags(defaults: const {}),
);
