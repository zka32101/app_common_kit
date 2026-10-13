/// 送る前の整形。個人情報らしい部分（メールアドレス・長いトークン・電話番号らしい数字）を伏せ、長さを切り詰める。
/// クラッシュ収集（`CrashReporter.scrub`）と診断情報で、同じ規則を使う。
String scrubText(String text, {int maxLength = 300}) {
  var t = text
      .replaceAll(RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+'), '[email]')
      .replaceAll(RegExp(r'\b[A-Za-z0-9_\-]{32,}\b'), '[token]')
      .replaceAll(RegExp(r'\b\d[\d\- ]{8,}\d\b'), '[number]');
  if (t.length > maxLength) t = t.substring(0, maxLength);
  return t;
}

/// 直近の操作の記録（メモリ上だけ。古いものから捨てる）。
///
/// 不具合報告に「診断情報」として添えるためのもの。**端末の外へは、利用者が報告を送るときだけ出る**
/// （送る前に、内容を画面で確認できる）。記録の中身は [scrubText] で整形する。
class DiagnosticLog {
  DiagnosticLog({this.capacity = 50, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// 残す件数。
  final int capacity;
  final DateTime Function() _clock;
  final List<({DateTime at, String message})> _entries = [];

  void add(String message) {
    _entries.add((at: _clock(), message: scrubText(message)));
    if (_entries.length > capacity) _entries.removeAt(0);
  }

  /// 新しい順ではなく、古い順の行（`HH:MM:SS 内容`）。
  List<String> lines() => [
        for (final e in _entries)
          '${_two(e.at.hour)}:${_two(e.at.minute)}:${_two(e.at.second)} ${e.message}',
      ];

  bool get isEmpty => _entries.isEmpty;

  void clear() => _entries.clear();

  static String _two(int n) => n.toString().padLeft(2, '0');
}
