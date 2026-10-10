import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// クラッシュ・エラーの送り先。Firebase Crashlytics や Sentry などをアプリが実装して渡す
/// （キットはプラグインに依存しない）。
abstract class CrashBackend {
  Future<void> recordError(Object error, StackTrace? stack, {required bool fatal, String? reason});

  /// 直前の操作の記録（クラッシュ報告に添える）。
  Future<void> log(String message);
}

/// テスト・プレビュー用。送られたエラーを記録するだけ。
class FakeCrashBackend implements CrashBackend {
  final List<({Object error, bool fatal, String? reason})> errors = [];
  final List<String> logs = [];

  @override
  Future<void> recordError(Object error, StackTrace? stack, {required bool fatal, String? reason}) async =>
      errors.add((error: error, fatal: fatal, reason: reason));

  @override
  Future<void> log(String message) async => logs.add(message);
}

/// 全アプリ共通のクラッシュ収集の口。個人情報の混入を防ぎ、送信の失敗でアプリを止めない。
///
/// - 同意が無い・使わないアプリでは [backend] を null にする（何もしない）
/// - 理由・ログの文字列から、メールアドレス・長いトークンらしい文字列・電話番号らしい数字列を伏せる
/// - 同じエラーを短時間に何度も送らない（[dedupeWindow]）
/// - 送信の例外は握りつぶす
///
/// 使い方: `main()` で `ProviderContainer` か直接 `CrashReporter(MyBackend()).install()` を呼ぶ。
class CrashReporter {
  CrashReporter(this.backend, {this.dedupeWindow = const Duration(minutes: 1), DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  /// null なら何もしない。
  CrashBackend? backend;

  /// 同じ種類・同じ理由のエラーを、この間は1回だけ送る。
  final Duration dedupeWindow;
  final DateTime Function() _clock;
  final Map<String, DateTime> _sent = {};

  static const maxLogLength = 300;
  static final _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');
  static final _token = RegExp(r'\b[A-Za-z0-9_\-]{32,}\b');
  static final _digits = RegExp(r'\b\d[\d\- ]{8,}\d\b');

  /// 送る前の整形（テストしやすいよう公開）。個人情報らしい部分を伏せ、長さを切り詰める。
  static String scrub(String text) {
    var t = text
        .replaceAll(_email, '[email]')
        .replaceAll(_token, '[token]')
        .replaceAll(_digits, '[number]');
    if (t.length > maxLogLength) t = t.substring(0, maxLogLength);
    return t;
  }

  /// エラーを送る。送った（試みた）なら true。重複・送り先なしは false。
  Future<bool> record(Object error, StackTrace? stack, {bool fatal = false, String? reason}) async {
    final b = backend;
    if (b == null) return false;
    final key = '${error.runtimeType}|${reason ?? ''}';
    final now = _clock();
    final last = _sent[key];
    if (last != null && now.difference(last) < dedupeWindow) return false;
    _sent[key] = now;
    try {
      await b.recordError(error, stack, fatal: fatal, reason: reason == null ? null : scrub(reason));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 直前の操作を記録する（クラッシュ報告に添わる）。
  Future<void> log(String message) async {
    final b = backend;
    if (b == null) return;
    try {
      await b.log(scrub(message));
    } catch (_) {}
  }

  /// Flutter とプラットフォームの未処理エラーをこの窓口へ流す。`runApp` の前に1回呼ぶ。
  /// 既存のハンドラは、置き換えずに先に呼ぶ（デバッグ表示を残す）。
  void install() {
    final prevFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      prevFlutter?.call(details);
      record(details.exception, details.stack, fatal: true, reason: details.context?.toString());
    };
    final prevPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, fatal: true);
      return prevPlatform?.call(error, stack) ?? true;
    };
  }
}

/// アプリの `ProviderScope` で `crashReporterProvider.overrideWithValue(CrashReporter(MyBackend()))` する。
/// 既定は送り先なし（何もしない）。
final crashReporterProvider = Provider<CrashReporter>((ref) => CrashReporter(null));
