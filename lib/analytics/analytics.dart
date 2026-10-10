import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 分析の送り先。Firebase Analytics などをアプリが実装して渡す（キットはプラグインに依存しない）。
abstract class AnalyticsBackend {
  Future<void> logEvent(String name, Map<String, Object> params);
}

/// テスト・プレビュー用。送られたイベントを記録するだけ。
class FakeAnalyticsBackend implements AnalyticsBackend {
  final List<({String name, Map<String, Object> params})> events = [];

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async =>
      events.add((name: name, params: params));
}

/// 全アプリ共通のイベント名。アプリ間で同じ指標を比べられるよう、名前をそろえる。
abstract class AnalyticsEvents {
  static const sessionStart = 'session_start_app';
  static const studyStart = 'study_start';
  static const studyComplete = 'study_complete';
  static const mockExamComplete = 'mock_exam_complete';
  static const purchaseStart = 'purchase_start';
  static const purchaseSuccess = 'purchase_success';
  static const feedbackSent = 'feedback_sent';
  static const reviewPromptShown = 'review_prompt_shown';
  static const updatePromptShown = 'update_prompt_shown';
  static const languageChanged = 'language_changed';
}

/// 共通の送り口。個人情報の混入を防ぎ、送信の失敗でアプリを止めない。
///
/// - イベント名: 英小文字・数字・`_`、先頭は英字、40字以内（Firebase の制約）。違反は送らない
/// - パラメータ: 25個まで。キーも同じ規則。文字列は100字まで切り詰める。
///   値は String / num / bool のみ。個人情報らしいキー（email・name・phone・uid など）は落とす
/// - 送信の例外は握りつぶす
class Analytics {
  Analytics(this.backend);

  /// null なら何もしない（分析を使わないアプリ・同意前）。
  AnalyticsBackend? backend;

  static final _nameRe = RegExp(r'^[a-z][a-z0-9_]{0,39}$');
  static const _piiKeys = {
    'email', 'mail', 'name', 'phone', 'tel', 'address', 'uid', 'user_id', 'userid', 'token', 'password', 'ip',
  };
  static const maxParams = 25;
  static const maxValueLength = 100;

  static bool isValidName(String name) => _nameRe.hasMatch(name);

  static bool _isPiiKey(String key) {
    final k = key.toLowerCase();
    return _piiKeys.contains(k) || _piiKeys.any((p) => k.endsWith('_$p'));
  }

  /// 送る前の整形（テストしやすいよう公開）。
  static Map<String, Object> sanitize(Map<String, Object?> params) {
    final out = <String, Object>{};
    for (final e in params.entries) {
      if (out.length >= maxParams) break;
      final v = e.value;
      if (v == null || !isValidName(e.key) || _isPiiKey(e.key)) continue;
      if (v is String) {
        out[e.key] = v.length > maxValueLength ? v.substring(0, maxValueLength) : v;
      } else if (v is num || v is bool) {
        out[e.key] = v;
      }
    }
    return out;
  }

  /// イベントを送る。送った（試みた）なら true。
  Future<bool> log(String name, [Map<String, Object?> params = const {}]) async {
    final b = backend;
    if (b == null || !isValidName(name)) return false;
    try {
      await b.logEvent(name, sanitize(params));
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// アプリの `ProviderScope` で `analyticsProvider.overrideWithValue(Analytics(MyBackend()))` する。
/// 既定は送り先なし（何もしない）。
final analyticsProvider = Provider<Analytics>((ref) => Analytics(null));
