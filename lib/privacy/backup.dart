import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// バックアップの 1 区画（設定・進捗など）。アプリが持つデータごとに 1 つ作る。
abstract class BackupSource {
  /// 区画の名前。バックアップ内のキーになる（同じアプリ内で重複させない・変えない）。
  String get name;

  /// JSON にできる値（Map / List / String / num / bool / null）で返す。
  Future<Object?> export();

  /// [export] が返した形の値を受け取って書き戻す。
  Future<void> restore(Object? data);
}

/// `SharedPreferences` の指定キー（または接頭辞）をそのまま入れ物にする。
///
/// 対応する型は bool / int / double / String / List<String>。
class SharedPreferencesBackupSource implements BackupSource {
  SharedPreferencesBackupSource(
    this.name, {
    this.keys = const {},
    this.prefixes = const [],
  });

  @override
  final String name;

  /// 対象のキー。
  final Set<String> keys;

  /// 対象のキーの接頭辞。
  final List<String> prefixes;

  bool _target(String key) =>
      keys.contains(key) || prefixes.any(key.startsWith);

  @override
  Future<Object?> export() async {
    final p = await SharedPreferences.getInstance();
    return {
      for (final k in p.getKeys())
        if (_target(k)) k: p.get(k),
    };
  }

  @override
  Future<void> restore(Object? data) async {
    if (data is! Map)
      throw const FormatException('SharedPreferences の区画は Map が必要です');
    final p = await SharedPreferences.getInstance();
    for (final e in data.entries) {
      final k = e.key as String;
      // 他の区画のキーを書き換えられないよう、対象のキーだけ受け付ける。
      if (!_target(k)) continue;
      final v = e.value;
      if (v is bool) {
        await p.setBool(k, v);
      } else if (v is int) {
        await p.setInt(k, v);
      } else if (v is double) {
        await p.setDouble(k, v);
      } else if (v is String) {
        await p.setString(k, v);
      } else if (v is List) {
        await p.setStringList(k, v.cast<String>());
      }
    }
  }
}

/// 任意のコールバックで区画を作る（Firestore・独自ストアなど）。
class CallbackBackupSource implements BackupSource {
  CallbackBackupSource(
    this.name, {
    required this.onExport,
    required this.onRestore,
  });

  @override
  final String name;
  final Future<Object?> Function() onExport;
  final Future<void> Function(Object? data) onRestore;

  @override
  Future<Object?> export() => onExport();

  @override
  Future<void> restore(Object? data) => onRestore(data);
}

/// 復元の結果。
class BackupRestoreResult {
  const BackupRestoreResult({
    required this.restored,
    required this.failed,
    required this.skipped,
  });

  /// 書き戻せた区画。
  final List<String> restored;

  /// 失敗した区画 → 理由。
  final Map<String, String> failed;

  /// バックアップに入っていなかった（または今のアプリにない）区画。
  final List<String> skipped;

  bool get ok => failed.isEmpty;
}

/// バックアップを読めなかったとき。
class BackupFormatException implements Exception {
  const BackupFormatException(this.message);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// 設定・進捗の書き出しと復元（機種変更用）。JSON 文字列で受け渡す。ファイルの保存・共有はアプリ側。
///
/// - 別のアプリのバックアップは受け付けない（[appId] が違えば [BackupFormatException]）
/// - 新しい形式（[formatVersion] より大きい）のバックアップは受け付けない
/// - 復元は区画ごとに行い、失敗した区画があっても他は続ける（結果は [BackupRestoreResult]）
/// - 個人情報（氏名・連絡先など）は区画に入れないこと。入れる前に [BackupSource] の中身を確認する
class BackupService {
  BackupService({
    required this.appId,
    required this.sources,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const formatVersion = 1;

  final String appId;
  final List<BackupSource> sources;
  final DateTime Function() _clock;

  Future<String> exportJson() async {
    final sections = <String, Object?>{};
    for (final s in sources) {
      sections[s.name] = await s.export();
    }
    return jsonEncode({
      'format': formatVersion,
      'appId': appId,
      'exportedAt': _clock().toUtc().toIso8601String(),
      'sections': sections,
    });
  }

  Future<BackupRestoreResult> restoreJson(String json) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const BackupFormatException('バックアップを読めませんでした');
    }
    if (decoded is! Map) throw const BackupFormatException('バックアップを読めませんでした');
    final format = decoded['format'];
    if (format is! int || format < 1 || format > formatVersion) {
      throw const BackupFormatException('このバックアップの形式には対応していません');
    }
    if (decoded['appId'] != appId) {
      throw const BackupFormatException('別のアプリのバックアップです');
    }
    final sections = decoded['sections'];
    if (sections is! Map) throw const BackupFormatException('バックアップを読めませんでした');

    final restored = <String>[];
    final failed = <String, String>{};
    final skipped = <String>[];
    for (final s in sources) {
      if (!sections.containsKey(s.name)) {
        skipped.add(s.name);
        continue;
      }
      try {
        await s.restore(sections[s.name]);
        restored.add(s.name);
      } catch (e) {
        failed[s.name] = e.toString();
      }
    }
    return BackupRestoreResult(
      restored: restored,
      failed: failed,
      skipped: skipped,
    );
  }
}
