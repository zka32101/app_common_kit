import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'diagnostic_log.dart';

/// 不具合報告に添える「診断情報」を組み立てる。
///
/// 含めるのは、アプリの名前と版、プラットフォームと OS の版、言語、アプリが渡す補足 [extra]、
/// 直近の操作の記録 [log]。**利用者の識別子・名前・メールアドレスは含めない**
/// （文字列はすべて [scrubText] で整形する）。
/// 送る前に、利用者が画面で内容を確認でき、チェックを外せば添えない（`FeedbackFormPage`）。
class DiagnosticsCollector {
  DiagnosticsCollector({
    required this.appName,
    this.appVersion = '',
    this.extra = const {},
    this.log,
    this.maxLength = 3000,
    String Function()? platformInfo,
    String Function()? localeInfo,
  })  : _platformInfo = platformInfo ?? _defaultPlatform,
        _localeInfo = localeInfo ?? _defaultLocale;

  final String appName;
  final String appVersion;

  /// アプリが足す補足（例: `{'購入': 'プレミアム'}`）。値は整形する。
  final Map<String, String> extra;
  final DiagnosticLog? log;
  final int maxLength;
  final String Function() _platformInfo;
  final String Function() _localeInfo;

  static String _defaultPlatform() {
    if (kIsWeb) return 'Web';
    try {
      return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    } catch (_) {
      return 'unknown';
    }
  }

  static String _defaultLocale() {
    try {
      return PlatformDispatcher.instance.locale.toLanguageTag();
    } catch (_) {
      return 'unknown';
    }
  }

  /// 診断情報（そのまま画面に出せる文字列）。長さは [maxLength] までで、記録は新しいものを優先して残す。
  String collect() {
    final head = <String>[
      'app: ${scrubText(appName, maxLength: 100)}',
      'version: ${scrubText(appVersion, maxLength: 50)}',
      'platform: ${scrubText(_platformInfo(), maxLength: 200)}',
      'locale: ${scrubText(_localeInfo(), maxLength: 50)}',
      for (final e in extra.entries) '${scrubText(e.key, maxLength: 50)}: ${scrubText(e.value, maxLength: 200)}',
    ];
    final headText = head.join('\n');
    final lines = log?.lines() ?? const <String>[];
    if (lines.isEmpty) return _cap(headText);

    // 先頭の情報を必ず残し、残りの長さに入るだけ、新しい記録から詰める。
    final room = maxLength - headText.length - '\n\nrecent:\n'.length;
    final kept = <String>[];
    var used = 0;
    for (final l in lines.reversed) {
      final cost = l.length + 1;
      if (used + cost > room) break;
      kept.insert(0, l);
      used += cost;
    }
    if (kept.isEmpty) return _cap(headText);
    return _cap('$headText\n\nrecent:\n${kept.join('\n')}');
  }

  String _cap(String s) => s.length > maxLength ? s.substring(0, maxLength) : s;
}

/// アプリの `ProviderScope` で `diagnosticLogProvider.overrideWithValue(log)` する。
/// 既定は、このプロセスだけの空の記録。
final diagnosticLogProvider = Provider<DiagnosticLog>((ref) => DiagnosticLog());

/// 診断情報を添えるチェックの文言。内蔵: ja・en・zh・zh-Hant・ko（zh・zh-Hant・ko は機械翻訳の下書き）。
class DiagnosticsStrings {
  const DiagnosticsStrings({
    required this.attach,
    required this.attachHint,
    required this.preview,
    required this.close,
  });

  final String attach;
  final String attachHint;
  final String preview;
  final String close;

  /// `KitStrings.languageCode`（`ja`・`en`・`zh`・`zh-Hant`・`ko`）に合わせて選ぶ。それ以外は日本語。
  static DiagnosticsStrings forCode(String code) => switch (code) {
        'en' => en,
        'zh' => zhHans,
        'zh-Hant' => zhHant,
        'ko' => ko,
        _ => ja,
      };

  static const ja = DiagnosticsStrings(
    attach: '診断情報を添える',
    attachHint: 'アプリの版・端末・直近の操作の記録を一緒に送ります。名前やメールアドレスは含みません。',
    preview: '送る内容を見る',
    close: '閉じる',
  );
  static const en = DiagnosticsStrings(
    attach: 'Attach diagnostic info',
    attachHint: 'Sends the app version, device and recent actions. It does not include your name or email address.',
    preview: 'See what will be sent',
    close: 'Close',
  );
  static const zhHans = DiagnosticsStrings(
    attach: '附带诊断信息',
    attachHint: '一并发送应用版本、设备和最近操作的记录，不含姓名或电子邮件地址。',
    preview: '查看将发送的内容',
    close: '关闭',
  );
  static const zhHant = DiagnosticsStrings(
    attach: '附上診斷資訊',
    attachHint: '一併傳送應用程式版本、裝置與最近操作的紀錄，不含姓名或電子郵件地址。',
    preview: '查看將傳送的內容',
    close: '關閉',
  );
  static const ko = DiagnosticsStrings(
    attach: '진단 정보 첨부',
    attachHint: '앱 버전, 기기, 최근 작업 기록을 함께 보냅니다. 이름이나 이메일 주소는 포함하지 않습니다.',
    preview: '보낼 내용 보기',
    close: '닫기',
  );
}
