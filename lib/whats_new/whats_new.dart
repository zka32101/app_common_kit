import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../update/app_update.dart' show compareVersions;

/// 1 つのバージョンで変わったこと。文面はアプリ側が現在の言語で渡す。
class WhatsNewEntry {
  const WhatsNewEntry({required this.version, required this.items});

  /// `1.2.0` 形式。`+build` や `-pre` は比較で無視する。
  final String version;

  /// 箇条書きの変更点。
  final List<String> items;
}

/// 最後に見せたバージョンの保存先。
abstract class WhatsNewStore {
  Future<String?> loadSeenVersion();
  Future<void> saveSeenVersion(String version);
  Future<void> clear();
}

class SharedPreferencesWhatsNewStore implements WhatsNewStore {
  SharedPreferencesWhatsNewStore(
    this.appId, {
    this.keyPrefix = 'kit_whats_new_',
  });

  final String appId;
  final String keyPrefix;

  String get _key => '$keyPrefix$appId';

  @override
  Future<String?> loadSeenVersion() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> saveSeenVersion(String version) async =>
      (await SharedPreferences.getInstance()).setString(_key, version);

  @override
  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

/// テスト・プレビュー用。
class InMemoryWhatsNewStore implements WhatsNewStore {
  String? _seen;

  @override
  Future<String?> loadSeenVersion() async => _seen;

  @override
  Future<void> saveSeenVersion(String version) async => _seen = version;

  @override
  Future<void> clear() async => _seen = null;
}

/// 更新後の初回起動で見せる変更点を決める。
///
/// - 初回インストール（保存なし）は何も見せず、現在のバージョンを記録する。
/// - 保存済みより新しく、現在以下のバージョンの [entries] を新しい順に返す。
class WhatsNew {
  WhatsNew({
    required this.store,
    required this.currentVersion,
    required this.entries,
  });

  final WhatsNewStore store;
  final String currentVersion;
  final List<WhatsNewEntry> entries;

  Future<List<WhatsNewEntry>> pending() async {
    final seen = await store.loadSeenVersion();
    if (seen == null) {
      await store.saveSeenVersion(currentVersion);
      return const [];
    }
    final list =
        entries
            .where(
              (e) =>
                  compareVersions(e.version, seen) > 0 &&
                  compareVersions(e.version, currentVersion) <= 0,
            )
            .toList()
          ..sort((a, b) => compareVersions(b.version, a.version));
    return list;
  }

  /// 見せ終えたら呼ぶ。現在のバージョンを記録する。
  Future<void> markSeen() => store.saveSeenVersion(currentVersion);
}

/// 画面の文言。内蔵: ja・en・zh・zh-Hant・ko（zh・zh-Hant・ko は機械翻訳の下書き）。
class WhatsNewStrings {
  const WhatsNewStrings({
    required this.title,
    required this.close,
    required this.versionLabel,
  });

  final String title;
  final String close;

  /// `v1.2.0` のような見出し。
  final String Function(String version) versionLabel;

  static String _v(String v) => 'v$v';

  static final _ja = WhatsNewStrings(
    title: '新しくなりました',
    close: '閉じる',
    versionLabel: _v,
  );
  static final _en = WhatsNewStrings(
    title: "What's new",
    close: 'Close',
    versionLabel: _v,
  );
  static final _zh = WhatsNewStrings(
    title: '更新内容',
    close: '关闭',
    versionLabel: _v,
  );
  static final _zhHant = WhatsNewStrings(
    title: '更新內容',
    close: '關閉',
    versionLabel: _v,
  );
  static final _ko = WhatsNewStrings(
    title: '새로운 기능',
    close: '닫기',
    versionLabel: _v,
  );

  static WhatsNewStrings forLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return _ja;
      case 'zh':
        return locale.scriptCode == 'Hant' ||
                locale.countryCode == 'TW' ||
                locale.countryCode == 'HK'
            ? _zhHant
            : _zh;
      case 'ko':
        return _ko;
      default:
        return _en;
    }
  }
}

/// 見せる変更点があれば表示し、閉じたら記録する。見せたら true。
Future<bool> showWhatsNewIfNeeded(
  BuildContext context,
  WhatsNew whatsNew, {
  WhatsNewStrings? strings,
}) async {
  final list = await whatsNew.pending();
  if (list.isEmpty || !context.mounted) return false;
  final s =
      strings ?? WhatsNewStrings.forLocale(Localizations.localeOf(context));
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s.title),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final e in list) ...[
              Text(
                s.versionLabel(e.version),
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              for (final item in e.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('・'),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(s.close),
        ),
      ],
    ),
  );
  await whatsNew.markSeen();
  return true;
}
